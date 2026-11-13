#!/bin/sh
# Fin de mandat : produit AILLEURS une copie du code sans aucune trace de la
# couche IA. Le dépôt de travail n'est jamais touché.
#
# Usage : decommission.sh <destination> [--remote <url>]
#
# POURQUOI UN EXPORT ET PAS UNE PURGE EN PLACE. Une purge est une commande
# destructive lancée une fois, dans l'urgence d'une fin de mandat, sur le seul
# exemplaire du travail. Un export est rejouable et s'inspecte avant livraison.
#
# POURQUOI PAS D'HISTORIQUE. Le client ne reçoit pas le `.git` : l'export est un
# dépôt neuf, un commit unique.
#
# POURQUOI ON NE POUSSE PAS. Pousser vers une infrastructure qui n'est pas la
# nôtre reste un geste humain, fait après inspection.

ID_PLUGIN_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ID_PLUGIN_ROOT/scripts/lib.sh"

dest=""
remote=""
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) remote=$2; shift 2 ;;
    *) dest=$1; shift ;;
  esac
done
[ -n "$dest" ] || die "Usage : decommission.sh <destination> [--remote <url>]"

src=$(git rev-parse --show-toplevel 2>/dev/null) || die "Pas un dépôt git : l'export s'appuie sur les fichiers suivis."
case "$dest" in /*) ;; *) dest="$PWD/$dest" ;; esac
if [ -e "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
  die "La destination « $dest » n'est pas vide. Choisir un répertoire neuf."
fi

# La couche IA : retirée de l'export.
is_ai_path() {
  case "$1" in
    .ia|.ia/*|.ia-ignore|specs|specs/*|.mcp.json|CLAUDE.md|CLAUDE.local.md|AGENTS.md|GEMINI.md|opencode.json) return 0 ;;
    .claude|.claude/*|.cursor|.cursor/*|.aiassistant|.aiassistant/*|.agents|.agents/*|.antigravity|.antigravity/*) return 0 ;;
    .github/copilot-instructions.md) return 0 ;;
  esac
  return 1
}

branch=$(git -C "$src" rev-parse --abbrev-ref HEAD 2>/dev/null)
mkdir -p "$dest"
kept=0
dropped=0
# Les fichiers SUIVIS par git : c'est la définition du code source du projet.
git -C "$src" ls-files -z | tr '\0' '\n' > "$dest/.id-files.tmp"
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  if is_ai_path "$rel"; then dropped=$((dropped + 1)); continue; fi
  [ -f "$src/$rel" ] || continue
  mkdir -p "$dest/$(dirname "$rel")"
  cp -p "$src/$rel" "$dest/$rel"
  kept=$((kept + 1))
done < "$dest/.id-files.tmp"
rm -f "$dest/.id-files.tmp"
say "Export depuis la branche « $branch » : $kept fichier(s), $dropped écarté(s) (couche IA)."

# Le contrôle qui prouve ce qui RESTE, par opposition à ce qu'on a pensé à retirer.
pattern='\.ia\b|\bclaude\b|\bbza(-(dev|laravel|sysadmin))?\b'
hits=$(cd "$dest" && { grep -rIniE "$pattern" . 2>/dev/null; find . -type f | grep -iE "$pattern"; } | grep -v '^\./\.git/' | head -n 41)
if [ -n "$hits" ]; then
  echo "$hits" | head -n 40 >&2
  die "Export non conforme : des traces de la couche IA subsistent (ci-dessus). L'export reste en place pour inspection : $dest. Corriger la SOURCE, puis relancer."
fi

# Dépôt neuf, commit unique : le client ne reçoit aucun historique.
git -C "$dest" init -q
git -C "$dest" add -A
# Le commit porte l'identité git du poste : c'est elle qui livre. Sans identité,
# on s'arrête plutôt que d'annoncer un export sans commit.
git -C "$dest" commit -q -m "Initial commit" \
  || die "Le commit de l'export a échoué (identité git absente ? git config --global user.name / user.email). L'export reste en place : $dest"
[ -n "$remote" ] && git -C "$dest" remote add origin "$remote"

say "✓ Export conforme — aucune trace de la couche IA : $dest"
say "  Dépôt neuf, un seul commit. RIEN N'A ÉTÉ POUSSÉ."
[ -n "$remote" ] && say "  Après inspection : git -C \"$dest\" push -u origin HEAD"
exit 0
