#!/bin/sh
# Tests des hooks du plugin bza, sans Claude : on leur donne l'entrée JSON que
# Claude Code leur donnerait, et on vérifie leur réponse.
cd "$(dirname "$0")/.." || exit 1
ROOT=$PWD
fail=0
guard="$ROOT/plugins/bza/scripts/bash-guard.sh"

expect() {
  # expect <décision attendue : deny|ask|allow> <commande>
  got=$(jq -n --arg c "$2" '{tool_name:"Bash", tool_input:{command:$c}}' | sh "$guard" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  [ -n "$got" ] || got=allow
  # Une commande sur plusieurs lignes s'affiche par sa première ligne.
  shown=$(printf '%s\n' "$2" | head -n 1)
  [ "$shown" = "$2" ] || shown="$shown …"
  if [ "$got" = "$1" ]; then printf '  ok   %-5s %s\n' "$1" "$shown"; else printf '  ✗    attendu %s, obtenu %s : %s\n' "$1" "$got" "$shown"; fail=1; fi
}

echo "bash-guard :"
expect allow 'git status'
expect allow 'git diff --cached -- src/a.php'
expect allow 'git add -- src/a.php src/b.php'
expect allow 'git commit -m "Corrige le calcul" -- src/a.php'
expect allow 'git log --oneline -5'
expect allow 'git checkout -b feature/x'
expect allow 'ls -la && echo push'
expect deny  'git add -A'
expect deny  'git add .'
expect deny  'git add --all'
expect deny  'git -C /tmp/projet add -u'
expect deny  'cd app && git add . && git commit -m x'
expect deny  'git commit -am "tout"'
expect deny  'git commit -a -m "tout"'
expect deny  'git commit --no-verify -m x -- a'
expect deny  'git push --force origin main'
expect deny  'git push -f origin master'
expect ask   'git push'
expect ask   'git push origin feature/x'
expect ask   'FOO=1 git push origin HEAD'
expect ask   'git push --force-with-lease origin feature/x'
expect ask   'git commit --amend --no-edit'
expect ask   'git reset --hard HEAD~1'
expect ask   'git clean -fd'
expect ask   'git checkout .'
expect ask   'git restore .'
expect ask   'git stash drop'
expect ask   'git rebase main'
expect ask   'echo ok; /usr/bin/git push'
expect allow 'rm -r build'
expect allow 'rm -f a.log'
expect allow 'ddev ssh'
expect allow 'git log --format=%an id'
expect deny  'rm -rf node_modules'
expect deny  'rm -fr /tmp/x'
expect deny  'rm -Rf vendor'
expect deny  'rm -r -f vendor'
expect deny  'rm --recursive --force vendor'
expect deny  '/bin/rm -rfv build'
expect deny  'cd x && sudo rm -rf .'
expect deny  'find . -name tmp | xargs rm -rf'
expect deny  'bash -c "rm -rf build"'
expect deny  'ssh deploy@serveur'
expect deny  '/usr/bin/ssh -p 2222 x'
expect deny  'cat .env'
expect deny  'grep DB_ .env'
expect deny  'echo X=1 >> .env'
expect deny  'source .env'
expect deny  'cat < app/.env.local'
expect deny  'docker compose --env-file=.env up'
expect deny  'git diff .env'
expect deny  'sed -n 1p .ddev/config.local.yaml'
expect deny  'printenv'
expect deny  'ddev exec printenv'
expect deny  'env'
expect deny  'export -p'
expect deny  'set'
expect deny  'E=/x/scripts/env.sh; sh $E keys .env'
expect allow 'cat .env.example'
expect allow 'diff .env.ddev .env.example'
expect deny  'cat .env.ddev.local'
expect allow 'ls -la .env'
expect allow '[ -f .env ]'
expect allow 'env FOO=1 make test'
expect allow 'export FOO=1'
expect allow 'sh /u/plugins/bza/scripts/env.sh keys .env'
expect allow 'sh "${CLAUDE_PLUGIN_ROOT}/scripts/env.sh" run .env -- php artisan migrate'
expect allow 'ddev start'

# Texte que le shell n'exécute pas : messages de commit, heredocs de données.
expect allow 'git commit -m "Plugin id en 0.2.2 ; plus de rm -rf ni de ssh" -- a.txt'
expect allow "git commit -m 'Voir \`id\` et \$(rm -rf x) : texte littéral' -- a.txt"
expect allow 'git commit --message="id 0.2.2" -- a.txt'
expect allow "git commit -F - -- a.txt <<'EOF'
Titre

Plugin \`id\` en 0.2.2.
id 0.2.2 : rm -rf retiré, ssh interdit.
EOF"
expect allow "git commit -m \"\$(cat <<'EOF'
id 0.2.2 : texte du message
EOF
)\" -- a.txt"
expect allow "cat > outil.sh <<'EOF'
rm -rf \"\$tmp\"
ssh serveur
EOF"
# … mais pas ce qui s'exécute vraiment.
expect deny  'git commit -m "texte $(rm -rf build)" -- a.txt'
expect deny  'git commit -m "texte `ssh serveur`" -- a.txt'
expect deny  "sh <<'EOF'
rm -rf build
EOF"
expect deny  "bash -s <<EOF
ssh serveur
EOF"
expect deny  "cat > x.sh <<EOF
\$(rm -rf build)
EOF"
expect deny  'git commit -m "ok" -- a.txt && rm -rf build'

echo "session-start :"
tmp=$(mktemp -d)
git -C "$tmp" init -q
out=$(jq -n --arg c "$tmp" '{cwd:$c}' | sh "$ROOT/plugins/bza/scripts/session-start.sh" | jq -r '.hookSpecificOutput.additionalContext')
case "$out" in *"bza:projet-init"*) echo "  ok   dépôt git sans .ia/ : création au premier besoin" ;; *) echo "  ✗    dépôt sans .ia/ : $out"; fail=1 ;; esac

sh "$ROOT/plugins/bza/scripts/ia-init.sh" "$tmp" >/dev/null
mkdir -p "$tmp/.ia/skills/maison" "$tmp/.ia/context/decisions"
printf -- '---\nname: maison\ndescription: test\n---\nCorps\n' > "$tmp/.ia/skills/maison/SKILL.md"
printf 'Le mot du projet est CAPYBARA.\n' > "$tmp/.ia/rules/regle.md"
printf '# `2026-11-01` — Choix de la base\n' > "$tmp/.ia/context/decisions/2026-11-01-base.md"
printf 'Remplacée par : 2026-11-01-base.md\n# `2026-10-01` — Ancien choix\n' > "$tmp/.ia/context/decisions/2026-10-01-ancien.md"
out=$(jq -n --arg c "$tmp" '{cwd:$c}' | sh "$ROOT/plugins/bza/scripts/session-start.sh" | jq -r '.hookSpecificOutput.additionalContext')
case "$out" in *CAPYBARA*) echo "  ok   règles du projet injectées" ;; *) echo "  ✗    règles absentes"; fail=1 ;; esac
case "$out" in *"Choix de la base"*) echo "  ok   décision active listée" ;; *) echo "  ✗    décision absente"; fail=1 ;; esac
case "$out" in *"Ancien choix"*) echo "  ✗    décision remplacée listée"; fail=1 ;; *) echo "  ok   décision remplacée ignorée" ;; esac
[ "$(readlink "$tmp/.claude/skills/maison")" = "../../.ia/skills/maison" ] && echo "  ok   lien .claude/skills/maison" || { echo "  ✗    lien absent"; fail=1; }
grep -qxF '/.claude/skills/maison' "$tmp/.git/info/exclude" && echo "  ok   lien ignoré localement" || { echo "  ✗    lien non ignoré"; fail=1; }
[ -z "$(git -C "$tmp" status --porcelain -- .claude)" ] && echo "  ok   aucun fichier suivi modifié par le hook" || { echo "  ✗    le hook laisse des changements"; fail=1; }
rm -rf "$tmp/.ia/skills/maison"
jq -n --arg c "$tmp" '{cwd:$c}' | sh "$ROOT/plugins/bza/scripts/session-start.sh" >/dev/null
[ -L "$tmp/.claude/skills/maison" ] && { echo "  ✗    lien orphelin conservé"; fail=1; } || echo "  ok   lien orphelin retiré"
touch "$tmp/.ia-ignore"
out=$(jq -n --arg c "$tmp" '{cwd:$c}' | sh "$ROOT/plugins/bza/scripts/session-start.sh")
[ -z "$out" ] && echo "  ok   .ia-ignore respecté" || { echo "  ✗    .ia-ignore ignoré"; fail=1; }
rm -rf "$tmp"

exit "$fail"
