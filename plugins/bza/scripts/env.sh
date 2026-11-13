#!/bin/sh
# Manipuler un fichier .env sans jamais en afficher les valeurs.
#
# Claude ne lit ni n'écrit les .env directement (réglages de l'organisation et
# hook bash-guard) : il passe par cet outil, qui lui donne les NOMS des
# variables, jamais leurs valeurs. Une valeur secrète arrive par 1Password
# (`set-op`), sans transiter par la conversation.
#
# Usage :
#   env.sh keys    <fichier>                     noms des variables, définies ou vides
#   env.sh check   <fichier> [<modèle>]          écart avec .env.example (ou le modèle donné)
#   env.sh init    <fichier> [<modèle>]          crée le fichier à partir du modèle
#   env.sh set     <fichier> <NOM> <valeur>      écrit une valeur NON secrète
#   env.sh set-op  <fichier> <NOM> <op://…>      écrit un secret lu dans 1Password
#   env.sh unset   <fichier> <NOM>               retire une variable
#   env.sh show    <fichier>                     affiche un modèle (.example, .dist, .sample, .template)
#   env.sh run     <fichier> -- <commande…>      lance la commande avec les variables chargées,
#                                                valeurs masquées dans sa sortie
#
# Limite assumée : `run` masque les valeurs telles qu'elles sont écrites dans le
# fichier. Une valeur transformée par la commande (encodée, découpée) peut
# encore apparaître.

ID_PLUGIN_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
. "$ID_PLUGIN_ROOT/scripts/lib.sh"

usage() { sed -n '9,18p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

valid_name() {
  printf '%s' "$1" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$' || die "Nom de variable invalide : $1"
}

# Noms et état des variables d'un fichier : une ligne « NOM défini|vide ».
# Accepte « NOM=… » et « export NOM=… » ; ignore commentaires et lignes vides.
list_vars() {
  awk '
    BEGIN { q = sprintf("%c", 39) }
    /^[[:space:]]*(#|$)/ { next }
    {
      line = $0
      sub(/^[[:space:]]*export[[:space:]]+/, "", line)
      eq = index(line, "=")
      if (eq == 0) next
      name = substr(line, 1, eq - 1); gsub(/[[:space:]]/, "", name)
      value = substr(line, eq + 1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value == "\"\"" || value == q q) value = ""
      print name, (value == "" ? "vide" : "défini")
    }' "$1"
}

# Écrit NOM=valeur : remplace la première définition, sinon ajoute en fin.
# La valeur passe par l'environnement, jamais par la ligne de commande d'awk.
#
# Une valeur avec espace ou caractère spécial s'écrit entre apostrophes : elle
# est alors littérale pour le shell comme pour les lecteurs .env (phpdotenv,
# Symfony) — pas d'interpolation de $, pas d'échappement. Les guillemets
# échappés ne servent qu'à une valeur qui contient elle-même une apostrophe.
write_var() {
  file=$1 name=$2
  tmp=$(mktemp) || die "Fichier temporaire impossible"
  ID_ENV_NAME=$name awk '
    BEGIN {
      name = ENVIRON["ID_ENV_NAME"]; value = ENVIRON["ID_ENV_VALUE"]
      q = sprintf("%c", 39)
      if (index(value, " ") || index(value, "\t") || index(value, "#") || index(value, "\"") || index(value, q) || index(value, "$") || index(value, "\\") || index(value, "`")) {
        if (!index(value, q)) value = q value q
        else { gsub(/\\/, "\\\\", value); gsub(/"/, "\\\"", value); gsub(/\$/, "\\$", value); value = "\"" value "\"" }
      }
      done = 0
    }
    {
      line = $0; probe = line
      sub(/^[[:space:]]*export[[:space:]]+/, "", probe)
      if (!done && index(probe, name "=") == 1) { print name "=" value; done = 1; next }
      print line
    }
    END { if (!done) print name "=" value }' "$file" > "$tmp" || { rm -f "$tmp"; die "Écriture impossible"; }
  # cat plutôt que mv : on garde les droits et le propriétaire du fichier.
  cat "$tmp" > "$file" && rm -f "$tmp"
}

# Un modèle est versionné, donc sans secret : il se lit. `.env.ddev` est le modèle
# DDEV versionné avec le projet.
is_template() {
  case "$(basename "$1")" in *.example|*.dist|*.sample|*.template|.env.ddev) return 0 ;; esac
  return 1
}

template_for() {
  if [ -n "$2" ]; then printf '%s\n' "$2"; else printf '%s\n' "$(dirname "$1")/.env.example"; fi
}

cmd=$1
[ -n "$cmd" ] || usage
shift
file=$1
[ -n "$file" ] || usage
shift

case "$cmd" in
  keys)
    [ -f "$file" ] || die "$file introuvable."
    list_vars "$file" | awk '{ printf "%s = %s\n", $1, $2 }' ;;

  check)
    [ -f "$file" ] || die "$file introuvable."
    model=$(template_for "$file" "$1")
    [ -f "$model" ] || die "Modèle introuvable : $model"
    a=$(mktemp) && b=$(mktemp) || die "Fichier temporaire impossible"
    list_vars "$file" | cut -d ' ' -f 1 | sort -u > "$a"
    list_vars "$model" | cut -d ' ' -f 1 | sort -u > "$b"
    missing=$(comm -13 "$a" "$b")
    extra=$(comm -23 "$a" "$b")
    empty=$(list_vars "$file" | awk '$2 == "vide" { print $1 }')
    rm -f "$a" "$b"
    [ -n "$missing" ] && { say "Absentes de $file (présentes dans $model) :"; printf '   %s\n' $missing; }
    [ -n "$extra" ] && { say "Présentes dans $file, absentes du modèle :"; printf '   %s\n' $extra; }
    [ -n "$empty" ] && { say "Vides dans $file :"; printf '   %s\n' $empty; }
    [ -z "$missing$extra$empty" ] && say "$file est complet par rapport à $model."
    exit 0 ;;

  init)
    [ -e "$file" ] && die "$file existe déjà : rien n'est écrasé."
    model=$(template_for "$file" "$1")
    [ -f "$model" ] || die "Modèle introuvable : $model"
    cp "$model" "$file"
    say "$file créé à partir de $model. Variables :"
    list_vars "$file" | awk '{ printf "   %s = %s\n", $1, $2 }' ;;

  set)
    [ $# -eq 2 ] || usage
    valid_name "$1"
    [ -f "$file" ] || : > "$file"
    ID_ENV_VALUE=$2
    export ID_ENV_VALUE
    write_var "$file" "$1"
    unset ID_ENV_VALUE
    say "$1 écrit dans $file." ;;

  set-op)
    [ $# -eq 2 ] || usage
    valid_name "$1"
    case "$2" in op://*) ;; *) die "Référence 1Password attendue (op://coffre/élément/champ)." ;; esac
    command -v op >/dev/null 2>&1 || die "La CLI 1Password (op) est introuvable sur ce poste."
    secret=$(op read "$2" 2>/dev/null) || die "1Password n'a pas pu lire $2 (session fermée ou référence inconnue)."
    [ -n "$secret" ] || die "1Password a renvoyé une valeur vide pour $2."
    [ -f "$file" ] || : > "$file"
    ID_ENV_VALUE=$secret
    export ID_ENV_VALUE
    write_var "$file" "$1"
    unset ID_ENV_VALUE secret
    say "$1 écrit dans $file depuis 1Password (valeur non affichée)." ;;

  unset)
    [ $# -eq 1 ] || usage
    valid_name "$1"
    [ -f "$file" ] || die "$file introuvable."
    tmp=$(mktemp) || die "Fichier temporaire impossible"
    ID_ENV_NAME=$1 awk '{ p = $0; sub(/^[[:space:]]*export[[:space:]]+/, "", p); if (index(p, ENVIRON["ID_ENV_NAME"] "=") == 1) next; print }' "$file" > "$tmp"
    cat "$tmp" > "$file" && rm -f "$tmp"
    say "$1 retiré de $file." ;;

  show)
    is_template "$file" || die "Refusé : $file peut contenir des secrets. Utiliser « keys » pour en voir les noms."
    [ -f "$file" ] || die "$file introuvable."
    cat "$file" ;;

  run)
    [ "$1" = "--" ] && shift
    [ $# -gt 0 ] || usage
    [ -f "$file" ] || die "$file introuvable."
    masks=$(mktemp) && status=$(mktemp) || die "Fichier temporaire impossible"
    # Les valeurs à masquer, une par ligne, guillemets retirés.
    awk '
      BEGIN { q = sprintf("%c", 39) }
      /^[[:space:]]*(#|$)/ { next }
      {
        l = $0; sub(/^[[:space:]]*export[[:space:]]+/, "", l); eq = index(l, "="); if (!eq) next
        v = substr(l, eq + 1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (length(v) >= 2 && substr(v, 1, 1) == q && substr(v, length(v)) == q) v = substr(v, 2, length(v) - 2)
        else if (length(v) >= 2 && substr(v, 1, 1) == "\"" && substr(v, length(v)) == "\"") {
          # Valeur telle que le shell la verra : échappements retirés.
          v = substr(v, 2, length(v) - 2)
          gsub(/\\\\/, "\001", v); gsub(/\\"/, "\"", v); gsub(/\\\$/, "$", v); gsub(/\\`/, "`", v); gsub(/\001/, "\\", v)
        }
        if (length(v) >= 4) print v
      }' "$file" > "$masks"
    # « . fichier » sans barre oblique chercherait le fichier dans le PATH.
    case "$file" in */*) src=$file ;; *) src=./$file ;; esac
    {
      # Le fichier chargé est celui du projet : rien que shellcheck puisse suivre.
      # shellcheck source=/dev/null
      ( set -a; . "$src"; set +a; "$@" ) 2>&1
      echo $? > "$status"
    } | awk -v masks="$masks" '
      BEGIN { while ((getline m < masks) > 0) if (m != "") v[++n] = m }
      {
        line = $0
        for (i = 1; i <= n; i++) {
          out = ""
          while ((p = index(line, v[i])) > 0) { out = out substr(line, 1, p - 1) "***"; line = substr(line, p + length(v[i])) }
          line = out line
        }
        print line
      }'
    code=$(cat "$status")
    rm -f "$masks" "$status"
    exit "${code:-1}" ;;

  *) usage ;;
esac
