#!/usr/bin/env bash
# Usage (local): bash install_or_update_cc_switch.sh
# Usage (remote): curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/install_or_update_cc_switch.sh | bash
# Supported: Debian/Ubuntu amd64 and arm64 via official CC Switch .deb package

set -euo pipefail

REPO="farion1231/cc-switch"
DEB_PATH="/tmp/cc-switch.deb"

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

need_cmd dpkg
need_cmd curl
need_cmd grep
need_cmd sudo
need_cmd apt

arch="$(dpkg --print-architecture)"

case "${arch}" in
    amd64)
        asset_arch="x86_64"
        ;;
    arm64)
        asset_arch="arm64"
        ;;
    *)
        warn "Architecture ${arch} is not supported by the official .deb package."
        warn "Please use the AppImage, .rpm package, or build CC Switch from source."
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

asset_name="CC-Switch-${tag}-Linux-${asset_arch}.deb"
url="https://github.com/${REPO}/releases/latest/download/${asset_name}"

log "Detected architecture: ${arch} (${asset_arch})"
log "Latest version: ${tag}"
log "Downloading CC Switch package: ${url}"
curl -fL --progress-bar "${url}" -o "${DEB_PATH}"

log "Installing CC Switch from ${DEB_PATH}"
sudo apt install -y "${DEB_PATH}"

log "Verifying installation..."
if command -v cc-switch >/dev/null 2>&1; then
    log "CC Switch installed successfully. Try: cc-switch"
else
    warn "cc-switch command was not found after installation. Please check apt output above."
    exit 1
fi
