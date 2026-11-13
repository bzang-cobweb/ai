#!/bin/sh
# Fait passer le `.ia/` d'un projet au format attendu par le plugin.
#
# Usage : migrate.sh plan  [répertoire]   — ce qui serait fait, sans rien toucher
#         migrate.sh apply [répertoire]   — le faire
#
# Chaque migration est un script `migrations/NNNN-<sujet>.sh` qui amène le
# format à NNNN. Il reçoit `plan|apply <racine>` et doit pouvoir être relancé
# sans dégât. Les migrations modifient des fichiers suivis par git : elles ne
# s'appliquent que sur demande, après lecture du plan, et ne commitent rien.

ID_PLUGIN_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ID_PLUGIN_ROOT/scripts/lib.sh"

mode=${1:-plan}
case "$mode" in plan|apply) ;; *) die "Usage : migrate.sh plan|apply [répertoire]" ;; esac
root=$(project_root "${2:-$PWD}")
[ -d "$root/.ia" ] || die "Pas de .ia/ dans $root."

current=$(ia_format_of "$root")
latest=$(ia_format_latest)

if [ "$current" -ge "$latest" ]; then
  say "Le .ia/ est déjà au format $latest. Rien à faire."
  exit 0
fi

say "Format actuel : $current — format attendu : $latest."
for m in "$ID_PLUGIN_ROOT"/migrations/[0-9]*.sh; do
  [ -f "$m" ] || continue
  target=$(basename "$m" | sed -E 's/^0*([0-9]+)-.*/\1/')
  [ "$target" -gt "$current" ] && [ "$target" -le "$latest" ] || continue
  say "── Migration vers le format $target : $(basename "$m" .sh)"
  sh "$m" "$mode" "$root" || die "La migration $(basename "$m") a échoué ; rien d'autre n'a été appliqué."
  if [ "$mode" = apply ]; then
    echo "$target" > "$root/.ia/VERSION"
    current=$target
  fi
done

if [ "$mode" = plan ]; then
  say "Plan seulement : rien n'a été modifié. Relancer avec « apply » pour l'appliquer."
else
  say "Fait. Le .ia/ est au format $current. Relire « git status », puis commiter par chemin."
fi
