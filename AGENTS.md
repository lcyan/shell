# Repository Guidelines

## Project Structure & Module Organization
This repository is a flat collection of Bash utilities at the repo root. `autoBestTrace.sh` is the main maintained route-test entrypoint, `besttrace-new.sh` is a closely related variant, and `autoBestTrace-old.sh` preserves legacy behavior. `install_or_update_fzf.sh` and `setup_dns.sh` are standalone system setup helpers. `dc8.sh` is deprecated and kept for reference. `besttrace2021` is a bundled binary asset; do not replace it casually. `README.md` contains user-facing usage notes.

## Build, Test, and Development Commands
There is no build system. Use shell-native validation before committing:

```bash
bash -n autoBestTrace.sh besttrace-new.sh install_or_update_fzf.sh setup_dns.sh
```

Checks Bash syntax without executing scripts.

```bash
shellcheck *.sh
```

Runs static analysis if `shellcheck` is installed.

```bash
sudo bash autoBestTrace.sh
```

Manual smoke test for the main workflow. Run root-required scripts only in a disposable VM or test host because several scripts change system state or depend on live network access.

## Coding Style & Naming Conventions
Write portable Bash with a `#!/bin/bash` or `#!/usr/bin/env bash` shebang, 4-space indentation, and quoted variable expansions unless word splitting is intentional. Prefer small helper functions such as `log()` or `next()` for repeated output. Use lowercase function names, uppercase constants like `FZF_DIR`, and descriptive script names with underscores only when the filename already follows that pattern.

## Testing Guidelines
This repo does not have an automated test suite yet. At minimum, every change should pass `bash -n` and, when available, `shellcheck`. For behavior changes, include a manual test note covering the exact command used, whether root was required, and the observed result. Test names are not applicable; keep any future test scripts in a dedicated `tests/` directory.

## Commit & Pull Request Guidelines
Recent history uses short, single-purpose commit subjects in either English or Chinese. Keep commits focused on one script or one behavior change, and mention the affected file or feature clearly. Pull requests should include a brief summary, risk notes for root/network changes, manual validation steps, and terminal screenshots or pasted output when CLI behavior changed.

## Safety & Configuration Tips
Avoid hardcoding secrets, API keys, or host-specific paths. Document any change that edits `/etc`, installs remote dependencies, or assumes `systemd`, `curl`, `git`, or `nexttrace` availability.
