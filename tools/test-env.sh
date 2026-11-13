#!/bin/sh
# Test de l'outil bza:env : il manipule un .env sans jamais en afficher une
# valeur, et masque les valeurs dans la sortie des commandes qu'il lance.
cd "$(dirname "$0")/.." || exit 1
ROOT=$PWD
E="$ROOT/plugins/bza/scripts/env.sh"
fail=0
ok() { printf '  ok   %s\n' "$1"; }
ko() { printf '  ✗    %s\n' "$1"; fail=1; }

tmp=$(mktemp -d)
cd "$tmp" || exit 1
printf 'APP_ENV=local\nDB_PASSWORD=\nexport API_KEY=\n# commentaire\nOLD=1\n' > .env.example

echo "env.sh :"
sh "$E" init .env >/dev/null && [ -f .env ] && ok "init depuis .env.example" || ko "init"
if sh "$E" init .env >/dev/null 2>&1; then ko "init écrase un .env existant"; else ok "init n'écrase rien"; fi
sh "$E" set .env APP_ENV production >/dev/null && grep -qx 'APP_ENV=production' .env && ok "set remplace une valeur" || ko "set remplace"
sh "$E" set .env NOUVELLE abc >/dev/null && grep -qx 'NOUVELLE=abc' .env && ok "set ajoute une variable" || ko "set ajoute"
if sh "$E" set .env 'MAUVAIS-NOM' x >/dev/null 2>&1; then ko "nom invalide accepté"; else ok "nom invalide refusé"; fi

# Faux 1Password : `op read` renvoie un secret que seul ce test connaît, avec
# des caractères qui demandent des guillemets ($, espace, apostrophe).
mkdir bin
cat > bin/op <<'OP'
#!/bin/sh
[ "$1" = read ] && printf '%s' "Tr\$s secret's"
OP
chmod +x bin/op
out=$(PATH="$tmp/bin:$PATH" sh "$E" set-op .env DB_PASSWORD op://coffre/item/password)
case "$out" in *secret*|*'Tr$s'*) ko "set-op affiche la valeur" ;; *) ok "set-op n'affiche pas la valeur" ;; esac
grep -q '^DB_PASSWORD=' .env && ok "set-op écrit le secret" || ko "set-op n'écrit rien"
if sh "$E" set-op .env X pas-une-ref >/dev/null 2>&1; then ko "référence non op:// acceptée"; else ok "référence non op:// refusée"; fi

keys=$(sh "$E" keys .env)
case "$keys" in *secret*|*production*) ko "keys affiche des valeurs" ;; *) ok "keys n'affiche que les noms" ;; esac
case "$keys" in *"DB_PASSWORD = défini"*) ok "keys : variable définie" ;; *) ko "keys : état faux" ;; esac
case "$keys" in *"API_KEY = vide"*) ok "keys : variable vide (avec export)" ;; *) ko "keys : export mal lu" ;; esac

chk=$(sh "$E" check .env)
case "$chk" in *NOUVELLE*) ok "check : variable hors modèle signalée" ;; *) ko "check : variable hors modèle" ;; esac

if sh "$E" show .env >/dev/null 2>&1; then ko "show affiche un .env"; else ok "show refuse un .env"; fi
sh "$E" show .env.example | grep -q APP_ENV && ok "show affiche le modèle" || ko "show modèle"
printf 'DRUPAL_TRANSLATION_CONTEXT="DEFAULT"\n' > .env.ddev
sh "$E" show .env.ddev | grep -q DEFAULT && ok "show affiche le modèle DDEV versionné" || ko "show .env.ddev"
rm -f .env.drupal
sh "$E" init .env.drupal .env.ddev >/dev/null && sh "$E" keys .env.drupal | grep -q 'DRUPAL_TRANSLATION_CONTEXT = défini' && ok "init depuis .env.ddev" || ko "init depuis .env.ddev"

out=$(sh "$E" run .env -- sh -c 'echo "valeur=$DB_PASSWORD"; exit 3')
code=$?
case "$out" in
  *secret*|*'Tr$s'*) ko "run laisse passer le secret : $out" ;;
  *'valeur=***'*) ok "run masque le secret" ;;
  *) ko "run : sortie inattendue : $out" ;;
esac
[ "$code" -eq 3 ] && ok "run rend le code de retour de la commande" || ko "run : code $code au lieu de 3"

sh "$E" unset .env OLD >/dev/null && ! grep -q '^OLD=' .env && ok "unset retire la variable" || ko "unset"
grep -q '^# commentaire' .env && ok "commentaires conservés" || ko "commentaires perdus"

cd "$ROOT" && rm -r -f "$tmp"
exit "$fail"
