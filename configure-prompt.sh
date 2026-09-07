#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

TARGET=/etc/bash.bashrc
START_MARKER='# >>> homelab prompt >>>'
END_MARKER='# <<< homelab prompt <<<'

# Replace our existing managed block so rerunning this script applies updates.
if grep -qF "$START_MARKER" "$TARGET"; then
  sed -i "/^${START_MARKER}$/,/^${END_MARKER}$/d" "$TARGET"
fi

cat >>"$TARGET" <<'EOF'

# >>> homelab prompt >>>
_homelab_prompt() {
  if (( EUID == 0 )); then
    PS1='\n\[\e[38;5;114m\]\h\[\e[0m\]:\[\e[38;5;117m\]\w\[\e[0m\]\n\[\e[1;38;5;203m\]\u\[\e[0m\] \$ '
  else
    PS1='\n\[\e[38;5;114m\]\h\[\e[0m\]:\[\e[38;5;117m\]\w\[\e[0m\]\n\[\e[38;5;229m\]\u\[\e[0m\] \$ '
  fi
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
