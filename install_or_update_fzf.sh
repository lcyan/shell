#!/usr/bin/env bash
# Usage (local): bash install_or_update_fzf.sh
# Usage (remote): curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/install_or_update_fzf.sh | bash

set -euo pipefail

FZF_DIR="${HOME}/.fzf"
BASHRC="${HOME}/.bashrc"
FZF_GIT_URL="https://github.com/junegunn/fzf.git"

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

append_if_missing() {
  local line="$1"
  local file="$2"

  if [ ! -f "$file" ]; then
    touch "$file"
  fi

  grep -Fqx "$line" "$file" || echo "$line" >> "$file"
}

log "Starting fzf install/update..."

if [ -d "${FZF_DIR}/.git" ]; then
  log "Existing fzf git repository detected at ${FZF_DIR}"
  log "Updating fzf repository..."
  git -C "${FZF_DIR}" pull --ff-only
elif [ -d "${FZF_DIR}" ]; then
  warn "${FZF_DIR} exists but is not a git repository."
  warn "Please move or remove it manually before running this script again."
  exit 1
else
  log "No existing installation found. Cloning fzf..."
  git clone --depth 1 "${FZF_GIT_URL}" "${FZF_DIR}"
fi

log "Running official fzf install script..."
"${FZF_DIR}/install" --all

log "Ensuring PATH priority in ${BASHRC}"
append_if_missing 'export PATH="$HOME/.fzf/bin:$PATH"' "${BASHRC}"

log "Ensuring bash integration in ${BASHRC}"
append_if_missing 'eval "$(fzf --bash)"' "${BASHRC}"

log "Reloading ${BASHRC} ..."
# shellcheck disable=SC1090
if ! source "${BASHRC}"; then
  warn "Failed to source ${BASHRC} in current shell."
  warn "Please open a new shell session or run: source ~/.bashrc"
fi

log "Verifying installation..."
printf 'which fzf: '
which fzf || true

printf 'fzf version: '
fzf --version || true

if fzf --bash >/dev/null 2>&1; then
  log "fzf --bash check: OK"
else
  warn "fzf --bash check failed"
fi

log "Done."
log "You can now test Ctrl-r / file completion in a new shell if needed."
