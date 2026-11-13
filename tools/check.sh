#!/bin/sh
# Contrôles du marketplace, en local comme en CI. Sortie non nulle au moindre écart.
#
# Ce que la synchro de l'organisation refuserait (bin/ à la racine d'un plugin,
# source non relative) et ce qu'elle accepterait mais qui casserait chez les
# utilisateurs (référence vers un skill qui n'existe pas, lois imposées pas à
# jour, hook qui ne refuse plus ce qu'il doit refuser).
cd "$(dirname "$0")/.." || exit 1
fail=0
ko() { printf '✗ %s\n' "$*"; fail=1; }

# --- JSON lisibles ---
json_files=$(find . -name '*.json' -not -path './.git/*')
for f in $json_files; do
  jq empty "$f" 2>/dev/null || ko "JSON invalide : $f"
done

# --- Marketplace et plugins ---
# Plugins tiers : seulement un dépôt GitHub public, figé sur un commit (`sha`).
# Un contenu tiers arrive chez tous les collaborateurs : il ne change qu'après
# relecture, par une pull request qui change le sha.
for entry in $(jq -r '.plugins[] | select(.source | type == "object") | "\(.name)=\(.source.source)=\(.source.sha // "")"' .claude-plugin/marketplace.json); do
  name=${entry%%=*}; rest=${entry#*=}; kind=${rest%%=*}; sha=${rest#*=}
  [ "$kind" = github ] || ko "$name : source tierce de type $kind, seule github est admise"
  printf '%s' "$sha" | grep -Eq '^[0-9a-f]{40}$' || ko "$name : plugin tiers non figé (sha de 40 caractères attendu)"
done
for entry in $(jq -r '.plugins[] | select(.source | type == "string") | "\(.name)=\(.source)"' .claude-plugin/marketplace.json); do
  name=${entry%%=*}; src=${entry#*=}
  case "$src" in ./*) ;; *) ko "$name : source non relative ($src), refusée par la synchro d'org" ;; esac
  manifest="$src/.claude-plugin/plugin.json"
  [ -f "$manifest" ] || { ko "$name : $manifest absent"; continue; }
  [ "$(jq -r .name "$manifest")" = "$name" ] || ko "$name : le nom du manifeste diffère de l'entrée du marketplace"
  jq -r .version "$manifest" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || ko "$name : version absente ou non semver"
  [ -e "$src/bin" ] && ko "$name : dossier bin/ à la racine, refusé par la synchro d'org"
  for dep in $(jq -r '.dependencies[]? | if type=="string" then . else .name end' "$manifest"); do
    jq -e --arg d "$dep" '.plugins[] | select(.name==$d)' .claude-plugin/marketplace.json >/dev/null || ko "$name : dépendance inconnue $dep"
  done
done
for d in plugins/*/; do
  n=$(basename "$d")
  jq -e --arg n "$n" '.plugins[] | select(.name==$n)' .claude-plugin/marketplace.json >/dev/null || ko "plugins/$n absent du marketplace"
done

# --- Skills et agents ---
for f in plugins/*/skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$f")")
  head -n 1 "$f" | grep -qx -- '---' || { ko "$f : pas d'en-tête"; continue; }
  n=$(sed -n '2,/^---$/p' "$f" | sed -n 's/^name: *//p' | head -n 1)
  desc=$(sed -n '2,/^---$/p' "$f" | sed -n 's/^description: *//p' | head -n 1)
  [ "$n" = "$dir" ] || ko "$f : name « $n » ≠ répertoire « $dir »"
  [ -n "$desc" ] || ko "$f : description vide"
  # En YAML, « # » précédé d'une espace ouvre un commentaire : la description serait coupée.
  case "$desc" in *" #"*) ko "$f : « # » dans la description, elle serait coupée (l'entourer d'accents graves)" ;; esac
done
for f in plugins/*/agents/*.md; do
  [ -f "$f" ] || continue
  n=$(sed -n '2,/^---$/p' "$f" | sed -n 's/^name: *//p' | head -n 1)
  [ "$n" = "$(basename "$f" .md)" ] || ko "$f : name « $n » ≠ fichier"
  # claude.ai écarte à la synchro un agent dont le nom fait moins de 3 caractères.
  [ "${#n}" -ge 3 ] || ko "$f : nom d'agent « $n » trop court (3 caractères minimum pour claude.ai)"
done

# --- Références id-*:<skill> ---
refs=$(grep -rhoE '`bza(-[a-z0-9]+)?:[a-z0-9-]+(/[a-z0-9.-]+)?' plugins managed README.md 2>/dev/null | tr -d '`' | sort -u)
for r in $refs; do
  plugin=${r%%:*}; rest=${r#*:}; item=${rest%%/*}; file=""
  case "$rest" in */*) file=${rest#*/} ;; esac
  base="plugins/$plugin"
  if [ -n "$file" ]; then
    [ -f "$base/skills/$item/$file" ] || ko "référence cassée : $r"
  else
    [ -f "$base/skills/$item/SKILL.md" ] || [ -f "$base/agents/$item.md" ] || ko "référence cassée : $r"
  fi
done

# --- Lois imposées à jour ---
expected=$(jq --rawfile md managed/claude-md.md '. + {claudeMd: $md}' managed/settings.base.json)
[ "$expected" = "$(jq . managed/settings.json)" ] || ko "managed/settings.json n'est pas à jour : lancer tools/build-managed.sh"

# --- Scripts ---
# Chaque script est lu par le shell de son en-tête : sh par défaut, bash s'il le
# déclare (les scripts du skill typo3-migration). shellcheck lit le même en-tête.
scripts=$(find plugins tools -name '*.sh')
for f in $scripts; do
  if head -n 1 "$f" | grep -q bash; then
    bash -n "$f" || ko "syntaxe bash : $f"
  else
    sh -n "$f" || ko "syntaxe sh : $f"
  fi
done
if command -v shellcheck >/dev/null 2>&1; then
  # shellcheck disable=SC2086 # découpage voulu : un argument par script
  shellcheck -S warning $scripts || ko "shellcheck"
fi
sh tools/test-hooks.sh || ko "tests des hooks"
sh tools/test-decommission.sh || ko "tests de la fin de mandat"
sh tools/test-env.sh || ko "tests de l'outil bza:env"

[ "$fail" -eq 0 ] && echo "✓ Marketplace conforme."
exit "$fail"
