#!/bin/sh
# Hook SessionStart — relie le `.ia/` du projet à Claude Code.
#
# Trois gestes, tous sans effet sur les fichiers suivis par git :
#  1. expose chaque skill de `.ia/skills/` par un lien `.claude/skills/<nom>`,
#     ignoré via `.git/info/exclude` (local au poste, jamais commité) ;
#  2. injecte les règles du projet (`.ia/rules/*.md`) dans la session ;
#  3. rappelle le contexte et le registre des décisions, et signale une
#     migration de format en attente.
#
# Claude Code découvre les skills AVANT ce hook : un lien posé ici ne sert qu'à
# la session suivante. Pour la session en cours, les nouveaux skills sont donc
# listés avec leur chemin, pour être lus directement.
#
# FAIL-OPEN : une erreur de ce hook ne doit jamais empêcher de travailler. Il
# se tait plutôt que de bloquer, sauf pour dire ce qui manque.

ID_PLUGIN_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ID_PLUGIN_ROOT/scripts/lib.sh"

input=$(cat)

if ! have_jq; then
  # Sans jq, pas de JSON : la sortie texte d'un SessionStart arrive aussi dans
  # le contexte, et c'est ce qui permet de prévenir l'utilisateur.
  echo "[bza] jq est introuvable sur ce poste (fourni par macOS 15 et plus) : les règles et skills du projet (.ia/) ne sont pas chargés. Le signaler à l'utilisateur."
  exit 0
fi

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$PWD
root=$(project_root "$cwd")

nl='
'

# Les skills appellent les scripts par ${CLAUDE_PLUGIN_ROOT} ; le chemin réel est
# donné ici aussi, pour le cas où la variable n'est pas résolue dans leur texte.
emit() {
  [ -n "$1" ] || exit 0
  jq -n --arg ctx "$1$nl${nl}[bza] Scripts du plugin bza : $ID_PLUGIN_ROOT/scripts" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
  exit 0
}

[ -f "$root/.ia-ignore" ] && exit 0

if [ ! -d "$root/.ia" ]; then
  is_git "$root" || exit 0
  emit "[bza] Ce dépôt git n'a pas de .ia/. Ne pas le créer d'office : le créer au premier besoin réel (une décision ou un contexte de projet à consigner) avec le skill bza:projet-init."
fi

ctx="[bza] Projet doté d'un .ia/ ($root/.ia). Lire .ia/context/project.md avant de travailler sur le projet ; consigner toute décision avec bza:decision."

# --- Format de .ia/ -----------------------------------------------------------
current=$(ia_format_of "$root")
latest=$(ia_format_latest)
if [ "$current" -lt "$latest" ] 2>/dev/null; then
  ctx="$ctx$nl${nl}[bza] Le .ia/ de ce projet est au format $current, le plugin attend le format $latest. Proposer à l'utilisateur de lancer /bza:migrer (rien n'est modifié sans son accord)."
fi

# --- Skills du projet : liens .claude/skills -> .ia/skills ---------------------
exclude=""
if is_git "$root"; then
  exclude=$(git -C "$root" rev-parse --git-path info/exclude 2>/dev/null)
  case "$exclude" in /*) ;; ?*) exclude="$root/$exclude" ;; esac
fi

new_skills=""
conflicts=""
for dir in "$root"/.ia/skills/*/; do
  [ -f "$dir/SKILL.md" ] || continue
  name=$(basename "$dir")
  link="$root/.claude/skills/$name"
  want="../../.ia/skills/$name"
  if [ -L "$link" ]; then
    [ "$(readlink "$link")" = "$want" ] && continue
    conflicts="$conflicts $name"
    continue
  fi
  if [ -e "$link" ]; then
    conflicts="$conflicts $name"
    continue
  fi
  mkdir -p "$root/.claude/skills" && ln -s "$want" "$link" || continue
  new_skills="$new_skills$nl- $name : lire .ia/skills/$name/SKILL.md"
  if [ -n "$exclude" ]; then
    mkdir -p "$(dirname "$exclude")"
    grep -qxF "/.claude/skills/$name" "$exclude" 2>/dev/null || echo "/.claude/skills/$name" >> "$exclude"
  fi
done

# Liens orphelins : un skill retiré de .ia/skills ne laisse pas de lien mort.
for link in "$root"/.claude/skills/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    ../../.ia/skills/*) [ -e "$link" ] || rm -f "$link" ;;
  esac
done

if [ -n "$new_skills" ]; then
  ctx="$ctx$nl${nl}[bza] Skills du projet ajoutés pour les prochaines sessions. Dans celle-ci, les lire directement au besoin :$new_skills"
fi
if [ -n "$conflicts" ]; then
  ctx="$ctx$nl${nl}[bza] Skills de .ia/skills non exposés, un fichier .claude/skills du même nom existe déjà :$conflicts. Le signaler à l'utilisateur."
fi

# --- Règles du projet ----------------------------------------------------------
rules=""
for f in "$root"/.ia/rules/*.md; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "README.md" ] && continue
  rules="$rules$nl$nl## $(basename "$f")$nl$nl$(cat "$f")"
done
if [ -n "$rules" ]; then
  ctx="$ctx$nl${nl}[bza] Règles propres à ce projet (.ia/rules). Elles complètent les lois sans jamais les contredire :$rules"
fi

# --- Registre des décisions : titres des entrées actives -----------------------
decisions=""
count=0
for f in "$root"/.ia/context/decisions/*.md; do
  [ -f "$f" ] || continue
  head -n 5 "$f" | grep -q '^Remplacée par' && continue
  count=$((count + 1))
  [ "$count" -gt 40 ] && continue
  title=$(grep -m 1 '^# ' "$f" | sed 's/^# //')
  decisions="$decisions$nl- $(basename "$f") — $title"
done
if [ "$count" -gt 0 ]; then
  more=""
  [ "$count" -gt 40 ] && more="$nl- … et $((count - 40)) autres dans .ia/context/decisions/"
  ctx="$ctx$nl${nl}[bza] Décisions actives du registre ($count). Un point qui y figure ne se re-signale pas ; lire l'entrée avant de rouvrir un sujet proche :$decisions$more"
fi

emit "$ctx"
