#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

TARGET=/etc/bash.bashrc
START_MARKER='# >>> homelab prompt >>>'
END_MARKER='# <<< homelab prompt <<<'

if grep -qF "$START_MARKER" "$TARGET"; then
  echo "Prompt already configured in $TARGET."
  exit 0
fi

cat >>"$TARGET" <<'EOF'

# >>> homelab prompt >>>
_homelab_prompt() {
  local user_colour

  if (( EUID == 0 )); then
    user_colour='\[\e[1m\e[38;5;203m\]'
  else
    user_colour='\[\e[1m\e[38;5;231m\]'
  fi

  local host_colour='\[\e[38;5;114m\]'
  local path_colour='\[\e[38;5;117m\]'

  PS1='\n'"${host_colour}"'\h\[\e[0m\]:'"${path_colour}"'\w\[\e[0m\]\n'"${user_colour}"'\u\[\e[0m\] \$ '
}

if [[ $- == *i* ]]; then
  if [[ -n ${PROMPT_COMMAND:-} ]]; then
    PROMPT_COMMAND="_homelab_prompt;${PROMPT_COMMAND}"
  else
    PROMPT_COMMAND='_homelab_prompt'
  fi
fi
# <<< homelab prompt <<<
EOF

echo "Done. Custom prompt configured for all interactive Bash users. Start a new shell to use it."
