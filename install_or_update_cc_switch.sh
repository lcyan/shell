#!/usr/bin/env bash
# Usage (local): bash install_or_update_cc_switch.sh
# Usage (remote): curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/install_or_update_cc_switch.sh | bash
# Supported: Linux amd64/x86_64 and arm64/aarch64 via official CC Switch .AppImage release

set -euo pipefail

REPO="farion1231/cc-switch"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
APP_PATH="${APP_PATH:-${INSTALL_DIR}/cc-switch.AppImage}"
CMD_PATH="${CMD_PATH:-${INSTALL_DIR}/cc-switch}"
TMP_PATH=""

log() {
    printf '[INFO] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        warn "Missing required command: $1"
        exit 1
    fi
}

cleanup() {
    if [ -n "${TMP_PATH}" ] && [ -f "${TMP_PATH}" ]; then
        rm -f "${TMP_PATH}"
    fi
}
trap cleanup EXIT

need_cmd uname
need_cmd curl
need_cmd grep
need_cmd mkdir
need_cmd chmod
need_cmd ln

arch="$(uname -m)"
case "${arch}" in
    x86_64|amd64)
        asset_arch="x86_64"
        ;;
    aarch64|arm64)
        asset_arch="arm64"
        ;;
    *)
        warn "Architecture ${arch} is not supported by the official Linux AppImage release."
        warn "Supported architectures: x86_64/amd64, arm64/aarch64."
        exit 1
        ;;
esac

api_url="https://api.github.com/repos/${REPO}/releases/latest"
log "Fetching latest CC Switch release metadata: ${api_url}"
release_json="$(curl -fsSL "${api_url}")"

tag="$(printf '%s' "${release_json}" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
if [ -z "${tag}" ]; then
    warn "Unable to detect latest release tag."
    exit 1
fi

asset_name="CC-Switch-${tag}-Linux-${asset_arch}.AppImage"
download_url="https://github.com/${REPO}/releases/latest/download/${asset_name}"

log "Detected architecture: ${arch} (${asset_arch})"
log "Latest version: ${tag}"
log "Downloading CC Switch AppImage: ${download_url}"
mkdir -p "${INSTALL_DIR}"
TMP_PATH="$(mktemp)"
curl -fL --progress-bar "${download_url}" -o "${TMP_PATH}"
chmod +x "${TMP_PATH}"
mv "${TMP_PATH}" "${APP_PATH}"
TMP_PATH=""
ln -sf "${APP_PATH}" "${CMD_PATH}"

log "Installed CC Switch to ${APP_PATH}"
log "Command symlink: ${CMD_PATH}"

if [ -x "${CMD_PATH}" ]; then
    log "Verifying installation..."
    "${CMD_PATH}" --version 2>/dev/null || log "CC Switch is installed. Launch it with: ${CMD_PATH}"
else
    warn "cc-switch command was not found after installation. Please check ${INSTALL_DIR}."
    exit 1
fi

case ":${PATH}:" in
    *":${INSTALL_DIR}:"*)
        ;;
    *)
        warn "${INSTALL_DIR} is not in PATH. Add it with: export PATH=\"${INSTALL_DIR}:\$PATH\""
        ;;
esac
