#!/bin/sh
# Crée le `.ia/` d'un projet à partir des gabarits du plugin.
#
# Usage : ia-init.sh [répertoire]
#
# N'écrase jamais rien : un fichier déjà présent est conservé tel quel. Ne
# commite rien : c'est à l'humain (ou à la session, avec son accord) de le faire.

ID_PLUGIN_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ID_PLUGIN_ROOT/scripts/lib.sh"

root=$(project_root "${1:-$PWD}")
[ -f "$root/.ia-ignore" ] && die "$root/.ia-ignore existe : ce dépôt ne doit porter aucune trace de la couche IA."

src="$ID_PLUGIN_ROOT/templates/ia"
created=""
kept=""

# Les gabarits, fichier par fichier, sans jamais écraser.
cd "$src" || die "Gabarits introuvables : $src"
for f in $(find . -type f | sed 's#^\./##' | sort); do
  dest="$root/.ia/$f"
  if [ -e "$dest" ]; then
    kept="$kept .ia/$f"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
    created="$created .ia/$f"
  fi
done

for d in context/decisions rules skills memory; do
  mkdir -p "$root/.ia/$d"
done

say "Projet : $root"
if [ -n "$created" ]; then
  say "Créés :"
  for f in $created; do echo "   $f"; done
fi
if [ -n "$kept" ]; then
  say "Déjà présents, conservés :"
  for f in $kept; do echo "   $f"; done
fi
say "Rien n'a été commité. À compléter d'abord : .ia/context/project.md"
