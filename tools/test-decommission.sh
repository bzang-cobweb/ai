#!/bin/sh
# Test de la fin de mandat sur un projet synthétique : la couche IA disparaît
# de l'export, le code reste, une trace oubliée dans la source bloque l'export.
cd "$(dirname "$0")/.." || exit 1
ROOT=$PWD
fail=0
ok() { printf '  ok   %s\n' "$1"; }
ko() { printf '  ✗    %s\n' "$1"; fail=1; }

# Identité git du « poste » de test : la CI n'en a pas, et l'export commite.
GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

work=$(mktemp -d)
cd "$work" || exit 1
mkdir projet && cd projet || exit 1
git init -q; git config user.email t@example.com; git config user.name t
mkdir -p .ia/context specs/done .claude/skills src
echo "# Contexte" > .ia/context/project.md
echo "# Demande" > specs/done/a.md
echo "lien" > .claude/settings.json
echo "<?php echo 'bonjour';" > src/index.php
echo '{"name":"app","devDependencies":{"vite":"^5"},"scripts":{"build":"vite build"}}' > package.json
echo "non suivi" > brouillon.txt
git add -- .ia specs .claude src package.json; git commit -qm init

sh "$ROOT/plugins/bza/scripts/decommission.sh" "$work/export" >/dev/null 2>&1 && ok "export conforme" || ko "export refusé"
[ -f "$work/export/src/index.php" ] && ok "code exporté" || ko "code absent"
[ ! -e "$work/export/.ia" ] && [ ! -e "$work/export/specs" ] && [ ! -e "$work/export/.claude" ] && ok "couche IA retirée" || ko "couche IA présente"
[ ! -e "$work/export/brouillon.txt" ] && ok "fichier non suivi non exporté" || ko "fichier non suivi exporté"
grep -q '"vite"' "$work/export/package.json" && ok "autres dépendances intactes" || ko "package.json abîmé"
[ "$(git -C "$work/export" rev-list --count HEAD)" = 1 ] && ok "dépôt neuf, un seul commit" || ko "historique incorrect"
[ -z "$(git -C "$work/export" remote)" ] && ok "aucun remote, rien poussé" || ko "remote inattendu"
[ -d .ia ] && [ -f specs/done/a.md ] && ok "dépôt de travail intact" || ko "dépôt de travail modifié"

echo "Voir .ia/context pour le contexte." > src/README.md
git add -- src/README.md; git commit -qm doc
sh "$ROOT/plugins/bza/scripts/decommission.sh" "$work/export2" >/dev/null 2>&1 && ko "trace oubliée non détectée" || ok "trace oubliée dans la source : export refusé"
git rm -q -- src/README.md; git commit -qm "retire la doc"

# Sans identité git, le commit de l'export échoue : le script doit le dire,
# pas annoncer un export réussi.
mkdir "$work/vide"
if env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL \
     HOME="$work/vide" GIT_CONFIG_NOSYSTEM=1 EMAIL= \
     sh "$ROOT/plugins/bza/scripts/decommission.sh" "$work/export3" >/dev/null 2>&1; then
  if [ "$(git -C "$work/export3" rev-list --count HEAD 2>/dev/null)" = 1 ]; then
    ok "sans identité git : git en a déduit une, export commité"
  else
    ko "sans identité git : export annoncé réussi sans commit"
  fi
else
  ok "sans identité git : export refusé avec un message"
fi

cd "$ROOT" && rm -rf "$work"
exit "$fail"
