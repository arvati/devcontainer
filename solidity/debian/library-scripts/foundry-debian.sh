#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Maintainer: Ademar Arvati Filho
#
# Syntax: ./foundry-debian.sh [branch version] [non-root user] [Add FOUNDRY_DIR to rc files flag] [FOUNDRY_DIR]


FOUNDRY_VERSION=${1:-"nightly"}
USERNAME=${2:-"automatic"}
UPDATE_RC=${3:-"true"}

# Folders
FOUNDRY_DIR=${4:-"/opt/foundry"}
FOUNDRY_MAN_DIR="$FOUNDRY_DIR/share/man/man1"

#FoundryUp
FOUNDRYUP_BIN_URL="https://raw.githubusercontent.com/foundry-rs/foundry/master/foundryup/foundryup"
FOUNDRYUP_BIN_PATH="$FOUNDRY_DIR/bin/foundryup"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/bash.bashrc
        fi
        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}


# Function to run apt-get if needed
apt_get_update_if_needed()
{
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update
    else
        echo "Skipping apt-get update."
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update_if_needed
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Run a command that should never fail. If the command fails execution
# will immediately terminate with an error showing the failing
# command.
ensure() {
  if ! "$@"; then err "command failed: $*"; fi
}

export DEBIAN_FRONTEND=noninteractive

# Install curl, tar, git, other dependencies if missing
check_packages curl ca-certificates gnupg2 tar
if ! type git > /dev/null 2>&1; then
    apt_get_update_if_needed
    apt-get -y install --no-install-recommends git
fi

architecture="$(uname -m)"
case $architecture in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    #aarch32 | armv7* | armvhf*) architecture="armv6l";;
    #i?86) architecture="386";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac

# Install Foundry
umask 0002
mkdir -p "${FOUNDRY_DIR}/bin" "${FOUNDRY_MAN_DIR}"

if [ ! -f "/usr/local/bin/forge" ]; then
    echo "Downloading Foundryup ..."
    set +e
    curl -# -L $FOUNDRYUP_BIN_URL -o $FOUNDRYUP_BIN_PATH
    exit_code=$?
    set -e
    chmod +x $FOUNDRYUP_BIN_PATH
    if [ "$exit_code" = "0" ]; then
        export FOUNDRY_DIR=${FOUNDRY_DIR-"/opt/foundry"}
        $FOUNDRYUP_BIN_PATH -v "${FOUNDRY_VERSION}"
    else
        echo "(!) Download Foundryup failed."
    fi
else
    echo "Foundry already installed. Skipping."
fi



# Add FOUNDRY_PATH bin directory into PATH in bashrc/zshrc files (unless disabled)
updaterc "$(cat << EOF
export FOUNDRY_PATH="${FOUNDRY_DIR}"
if [[ "\${PATH}" != *"\${FOUNDRY_PATH}/bin"* ]]; then export PATH="\${PATH}:\${FOUNDRY_PATH}/bin"; fi
EOF
)"

chmod -R g+r+w "${FOUNDRY_DIR}/bin"
find "${FOUNDRY_DIR}/bin" -type d | xargs -n 1 chmod g+s

ln -s "$FOUNDRY_DIR/bin/forge" "/usr/local/bin/forge"
ln -s "$FOUNDRY_DIR/bin/cast" "/usr/local/bin/cast"
ln -s "$FOUNDRY_DIR/bin/anvil" "/usr/local/bin/anvil"


echo "Done!"