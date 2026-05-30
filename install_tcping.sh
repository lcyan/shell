#!/usr/bin/env bash
# Usage (local): bash install_tcping.sh
# Usage (remote): curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/install_tcping.sh | bash
# Supported: Debian/Ubuntu amd64 and arm64 via official tcping .deb package

set -euo pipefail

REPO="pouriyajamshidi/tcping"
DEB_PATH="/tmp/tcping.deb"

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
need_cmd wget
need_cmd sudo
need_cmd apt

arch="$(dpkg --print-architecture)"

case "${arch}" in
    amd64|arm64)
        url="https://github.com/${REPO}/releases/latest/download/tcping-${arch}.deb"
        log "Detected architecture: ${arch}"
        log "Downloading tcping package: ${url}"
        wget -q --show-progress "${url}" -O "${DEB_PATH}"

        log "Installing tcping from ${DEB_PATH}"
        sudo apt install -y "${DEB_PATH}"

        log "Verifying installation..."
        if command -v tcping >/dev/null 2>&1; then
            tcping -v || true
            log "tcping installed successfully. Try: tcping www.example.com 443 -c 3"
        else
            warn "tcping command was not found after installation. Please check apt output above."
            exit 1
        fi
        ;;
    *)
        warn "Architecture ${arch} is not supported by the official .deb package."
        warn "Please use the tar.gz binary or build tcping from source."
        exit 1
        ;;
esac
