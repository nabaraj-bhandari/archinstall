#!/usr/bin/env bash

# git clone https://github.com/nabaraj-bhandari/archinstall &&
# cd archinstall && ./install.sh

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_DIR

source "$REPO_DIR/scripts/lib.sh"
source "$REPO_DIR/scripts/constants.sh"

# After reboot, systemd runs phase2 as the new user.

if [ "${1}" == "--phase2" ]; then
  source "$REPO_DIR/scripts/phase2.sh"
  exit 0
fi

source "$REPO_DIR/scripts/phase1.sh"
