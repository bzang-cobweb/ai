#!/bin/sh
# Hook PreToolUse (Bash) — les interdits des lois, en frontière plutôt qu'en vœu.
#
# Un prompt est une consigne ; ce hook tire AVANT l'outil Bash, y compris dans
# un sous-agent et en mode sans permission. Il a été écrit après un incident
# réel : un agent a lancé `git checkout package-lock.json` sur l'arbre partagé
# et détruit le travail non commité d'un autre.
#
# Les règles `permissions.deny` des réglages de l'organisation ne filtrent que
# le début d'une commande : `rm -rf *` laisse passer `rm -r -f` ou `/bin/rm -Rf`.
# Ce hook reconnaît les variantes.
#
#  - REFUS (deny) : ce qu'aucune instruction ne justifie —
#    · git : ajout global (`add -A`, `.`, `-u`), `commit -a`, `--no-verify`,
#      force-push sur main/master ;
#    · suppression récursive forcée (`rm -rf` sous toutes ses formes) ;
#    · connexion à une machine distante (`ssh`) ;
#    · tout accès direct à un fichier de secrets (`.env`, `.env.*` hors modèles,
#      `.ddev/config.local.yaml`) ailleurs que par l'outil `bza:env`, et les
#      commandes qui affichent tout l'environnement (`printenv`, `env`, `export -p`).
#  - CONFIRMATION (ask) : ce qu'un humain peut vouloir, mais doit décider lui-même
#    — tout push, `--amend`, et les opérations git qui réécrivent ou effacent l'arbre.
#
# FAIL-OPEN sur ses propres erreurs (entrée illisible, jq absent) : un garde-fou
# cassé ne doit pas paralyser le travail. Jamais sur une commande reconnue.
#
# Le découpage de la commande est volontairement simple. Avant de découper, on
# retire seulement le texte que le shell n'exécutera pas, et seulement quand on
# peut le prouver :
#  - la valeur d'un `-m` / `--message` entre apostrophes, ou entre guillemets
#    sans `$(` ni accent grave (sinon le shell l'exécuterait) ;
#  - le corps d'un heredoc, sauf s'il est donné à un interpréteur (sh, bash,
#    eval…) ou si son délimiteur non protégé laisse passer `$(` ou un accent grave.
# Un message de commit qui parle de `rm -rf` passe donc ; un
# `$(rm -rf …)` caché dans un message, non.

command -v jq >/dev/null 2>&1 || exit 0

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

cmd=$(printf '%s\n' "$cmd" | awk '
  BEGIN { q = sprintf("%c", 39); bq = sprintf("%c", 96); in_doc = 0 }
  in_doc {
    probe = $0
    if (strip_tabs) sub(/^\t+/, "", probe)
    if (probe == delim) { in_doc = 0; out = out $0 "\n"; next }
    if (keep || (!quoted && (index($0, "$(") || index($0, bq)))) out = out $0 "\n"
    else out = out "\n"
    next
  }
  {
    out = out $0 "\n"
    line = $0
    # Un « <<< » (chaîne en ligne) n est pas un heredoc.
    if (match(line, /<<-?[[:space:]]*["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/) && !(RSTART > 1 && substr(line, RSTART - 1, 1) == "<")) {
      spec = substr(line, RSTART + 2, RLENGTH - 2)
      strip_tabs = (substr(spec, 1, 1) == "-")
      if (strip_tabs) spec = substr(spec, 2)
      sub(/^[[:space:]]+/, "", spec)
      quoted = (substr(spec, 1, 1) == q || substr(spec, 1, 1) == "\"")
      gsub(/["\047]/, "", spec)
      delim = spec
      head = substr(line, 1, RSTART - 1)
      keep = (head ~ /(^|[[:space:];|&(])(sh|bash|zsh|dash|ksh|eval|source|\.|ssh|xargs)([[:space:]]|$)/)
      in_doc = 1
    }
  }
  END {
    # Valeurs de message : apostrophes toujours inertes ; guillemets seulement
    # sans substitution de commande.
    s = out; res = ""
    while (match(s, /(-m|--message)(=|[[:space:]]+)/)) {
      res = res substr(s, 1, RSTART + RLENGTH - 1)
      s = substr(s, RSTART + RLENGTH)
      c = substr(s, 1, 1)
      if (c == q || c == "\"") {
        rest = substr(s, 2); end = index(rest, c)
        if (end > 0) {
          val = substr(rest, 1, end - 1)
          if (c == q || (!index(val, "$(") && !index(val, bq))) { res = res c "MSG" c; s = substr(rest, end + 1); continue }
        }
      }
    }
    printf "%s", res s
  }')

decide() {
  jq -n --arg d "$1" --arg r "[bza] $2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

# Le verdict le plus fort l'emporte sur l'ensemble des segments.
verdict=""
reason=""
flag() {
  case "$1" in
    deny) verdict=deny; reason=$2 ;;
    ask) [ "$verdict" = deny ] || { verdict=ask; reason=$2; } ;;
  esac
}

check_git() {
  # $@ : les mots qui suivent `git`.
  # Options globales de git, avant la sous-commande.
  while [ $# -gt 0 ]; do
    case "$1" in
      -C|-c|--git-dir|--work-tree|--namespace|--exec-path) shift 2 ;;
      -*) shift ;;
      *) break ;;
    esac
  done
  [ $# -gt 0 ] || return 0
  sub=$1
  shift
  args=" $* "

  case "$sub" in
    add)
      for a in "$@"; do
        case "$a" in
          -A|--all|-u|--update|.|./|:/|'*'|--no-ignore-removal)
            flag deny "git add global refusé ($a) : ajouter les fichiers un à un, par leur chemin (loi git)." ;;
        esac
      done ;;
    commit)
      for a in "$@"; do
        case "$a" in
          --) break ;;
          --all|--no-verify) flag deny "git commit $a refusé : commit restreint par chemin, sans contourner les hooks (loi git)." ;;
          --amend) flag ask "git commit --amend réécrit l'historique : à confirmer par l'humain (loi git)." ;;
          --*) ;;
          -*[an]*)
            # Options courtes groupées : -a (tout indexer) ou -n (no-verify).
            # -m prend une valeur : on ne regarde que ce qui précède le m.
            pre=${a%%m*}
            case "$pre" in
              *a*) flag deny "git commit -a refusé : ajouter les fichiers un à un, par leur chemin (loi git)." ;;
              *n*) flag deny "git commit -n (--no-verify) refusé (loi git)." ;;
            esac ;;
        esac
      done ;;
    push)
      force=""
      case "$args" in *" -f "*|*" --force "*|*" --force-with-lease"*|*" +"*) force=1 ;; esac
      case "$args" in *" --no-verify "*) flag deny "git push --no-verify refusé (loi git)." ;; esac
      if [ -n "$force" ]; then
        case "$args" in
          *main*|*master*) flag deny "Force-push sur main/master refusé (loi git)." ;;
          *) flag ask "Force-push : réservé à l'humain, à confirmer (loi git)." ;;
        esac
      else
        flag ask "git push est réservé à l'humain : confirmer seulement s'il l'a demandé dans le chat (loi git)."
      fi ;;
    reset)
      case "$args" in *" --hard "*|*" --merge "*|*" --keep "*) flag ask "git reset destructif : à confirmer par l'humain (loi git)." ;; esac ;;
    clean)
      flag ask "git clean efface des fichiers non suivis : à confirmer par l'humain (loi git)." ;;
    checkout|restore)
      case "$args" in
        *" . "*|*" :/ "*|*" --staged "*|*" -f "*|*" --force "*)
          flag ask "git $sub sur l'arbre entier ou forcé : peut détruire du travail non commité, à confirmer (loi git)." ;;
      esac ;;
    stash)
      case "$args" in *" drop "*|*" clear "*) flag ask "git stash $1 efface du travail mis de côté : à confirmer (loi git)." ;; esac ;;
    branch)
      case "$args" in *" -D "*|*" --delete --force "*) flag ask "Suppression forcée de branche : à confirmer (loi git)." ;; esac ;;
    rebase|filter-branch|filter-repo)
      flag ask "git $sub réécrit l'historique : à confirmer par l'humain (loi git)." ;;
  esac
}

check_rm() {
  # $@ : les mots qui suivent `rm`. Refus si récursif ET forcé, quelle que soit
  # l'écriture : -rf, -fr, -Rf, -r -f, --recursive --force, -rfv…
  recursive=""
  force=""
  for a in "$@"; do
    case "$a" in
      --) break ;;
      --recursive) recursive=1 ;;
      --force) force=1 ;;
      --*) ;;
      -*)
        case "$a" in *[rR]*) recursive=1 ;; esac
        case "$a" in *f*) force=1 ;; esac ;;
    esac
  done
  if [ -n "$recursive" ] && [ -n "$force" ]; then
    flag deny "rm récursif forcé (rm -rf) interdit aux agents : demander à l'humain de le faire."
  fi
}

# Un mot désigne-t-il un fichier de secrets ? `.env` et `.env.*`, sauf les
# modèles versionnés (.example, .dist, .sample, .template, et `.env.ddev`, un
# modèle DDEV versionné), et `.ddev/config.local.yaml`.
# Couvre aussi `--env-file=.env` et les chemins (`app/.env`).
is_secret_file() {
  case "$1" in *config.local.yaml*) return 0 ;; esac
  w=${1##*=}
  b=${w##*/}
  case "$b" in
    .env) return 0 ;;
    .env.example|.env.dist|.env.sample|.env.template|.env.ddev) return 1 ;;
    .env.*) return 0 ;;
  esac
  return 1
}

# Afficher tout l'environnement revient à afficher les secrets qu'il contient.
check_env_dump() {
  case "$1" in
    printenv|*/printenv) flag deny "printenv affiche les secrets de l'environnement : passer par bza:env (keys, run)." ; return ;;
    export|declare|typeset)
      case " $* " in *" -p "*|" $1 ") flag deny "$1 affiche les variables de l'environnement, secrets compris : passer par bza:env." ;; esac
      return ;;
    set) [ $# -eq 1 ] && flag deny "set sans argument affiche les variables de l'environnement, secrets compris : passer par bza:env." ; return ;;
    env|*/env)
      shift
      for a in "$@"; do case "$a" in -*) ;; *) return ;; esac; done
      flag deny "env sans commande affiche les secrets de l'environnement : passer par bza:env (keys, run)." ;;
  esac
}

check_command() {
  # $@ : les mots d'une commande simple.
  [ $# -gt 0 ] || return 0
  check_env_dump "$@"
  for w in "$@"; do
    [ "$w" = printenv ] && flag deny "printenv affiche les secrets de l'environnement : passer par bza:env (keys, run)."
  done
  # Préfixes qui ne changent pas la commande lancée.
  while [ $# -gt 0 ]; do
    case "$1" in
      *=*|sudo|command|exec|env|nohup|time|nice|then|do|else|'{'|'!') shift ;;
      xargs)
        shift
        while [ $# -gt 0 ]; do case "$1" in -*) shift ;; *) break ;; esac; done ;;
      *) break ;;
    esac
  done
  [ $# -gt 0 ] || return 0
  prog=$1
  shift

  # L'outil bza:env est le seul passage autorisé vers un fichier de secrets.
  case "$prog" in
    */scripts/env.sh) return 0 ;;
    sh|*/sh|bash|*/bash)
      # Le chemin peut avoir été coupé par une espace une fois les guillemets retirés.
      case "$1" in */scripts/env.sh) return 0 ;; esac
      case "${2:-}" in */scripts/env.sh) return 0 ;; esac ;;
  esac
  # Savoir qu'un fichier existe ne révèle rien de son contenu.
  case "$prog" in
    ls|*/ls|test|'['|stat|*/stat) ;;
    *)
      # Le programme compte aussi : après une redirection, le fichier est en tête.
      for w in "$prog" "$@"; do
        if is_secret_file "$w"; then
          flag deny "Accès direct à un fichier de secrets ($w) refusé : passer par l'outil bza:env (keys, check, set, set-op, run). .ddev/config.local.yaml reste fermé."
          break
        fi
      done ;;
  esac

  case "$prog" in
    git|*/git) check_git "$@" ;;
    rm|*/rm) check_rm "$@" ;;
    ssh|*/ssh) flag deny "ssh interdit aux agents : la connexion à une machine distante reste un geste humain." ;;
    sh|*/sh|bash|*/bash|zsh|*/zsh|dash|*/dash)
      # `bash -c "…"` : la commande réelle est l'argument de -c.
      while [ $# -gt 0 ]; do
        case "$1" in
          -c|-*c) shift; check_command "$@"; return 0 ;;
          -*) shift ;;
          *) return 0 ;;
        esac
      done ;;
  esac
}

# Un segment par commande : séparateurs du shell, sous-shells, substitutions.
# Les guillemets sont retirés : `bash -c "rm -rf x"` se lit comme `rm -rf x`.
# Les redirections aussi séparent : `echo X >> .env` met `.env` en tête de segment.
segments=$(printf '%s\n' "$cmd" | tr ';|&()`<>' '\n\n\n\n\n\n\n\n' | tr -d "\"'")

set -f
old_ifs=$IFS
IFS='
'
for seg in $segments; do
  IFS=$old_ifs
  # shellcheck disable=SC2086 # découpage voulu en mots
  check_command $seg
  IFS='
'
done
IFS=$old_ifs

[ -n "$verdict" ] && decide "$verdict" "$reason"
exit 0
