#!/bin/sh
# plainbrain updater — refresh the kit-owned files (hooks, skills, CLI, project template)
# from this kit, backing up what it replaces. Leaves your data and merged config untouched.
# Thin wrapper over install.sh --update.
exec "$(cd "$(dirname "$0")" && pwd)/install.sh" --update
