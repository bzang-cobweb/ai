# shellcheck shell=sh
# Fonctions communes aux scripts du plugin `bza`. Sourcé, jamais exécuté.
#
# POSIX sh + jq : c'est tout ce qu'on peut supposer sur un Mac du parc
# (jq est fourni par macOS depuis la version 15). Aucun Node, aucun Python.

ID_PLUGIN_ROOT=${ID_PLUGIN_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}

# Version du format de `.ia/` que ce plugin sait lire.
ia_format_latest() {
  cat "$ID_PLUGIN_ROOT/templates/ia/VERSION"
}

# Version du format d'un `.ia/` existant. Un `.ia/` sans VERSION est au
# format 1, antérieur au format versionné.
ia_format_of() {
  if [ -f "$1/.ia/VERSION" ]; then tr -d '[:space:]' < "$1/.ia/VERSION"; else echo 1; fi
}

# Racine du dépôt git qui contient $1, ou $1 lui-même hors de git.
project_root() {
  git -C "$1" rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$1"
}

is_git() {
  git -C "$1" rev-parse --git-dir >/dev/null 2>&1
}

have_jq() {
  command -v jq >/dev/null 2>&1
}

say() {
  printf '[bza] %s\n' "$*"
}

die() {
  printf '[bza] ✗ %s\n' "$*" >&2
  exit 1
}
