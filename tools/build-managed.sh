#!/bin/sh
# Assemble les réglages imposés par l'organisation : les lois condensées
# (managed/claude-md.md) dans la clé claudeMd, plus managed/settings.base.json.
#
# Le résultat, managed/settings.json, est ce qu'un Owner colle dans
# claude.ai > Organization settings > Claude Code > Managed settings.
# Il est versionné ; la CI vérifie qu'il est à jour.
set -e
cd "$(dirname "$0")/.."
jq --rawfile md managed/claude-md.md '. + {claudeMd: $md}' managed/settings.base.json > managed/settings.json
echo "managed/settings.json régénéré."
