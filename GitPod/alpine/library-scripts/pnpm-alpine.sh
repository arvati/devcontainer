#!/bin/ash

set -e

PNPM_VERSION=${1:-"8.7.5"}
PNPM_HOME=${2:-"/opt/pnpm"}
USER_GID=${3:-"1000"}
SWITCHED_TO_BASH=${4:-"true"}
MARKER_FILE="/usr/local/etc/vscode-dev-containers/pnpm"

# Switch to bash right away
if [ "${SWITCHED_TO_BASH}" != "true" ]; then
    apk add bash
    export SWITCHED_TO_BASH=true
    exec /bin/bash "$0" "$@"
    exit $?
fi

SCRIPT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Load markers to see which steps have already run
if [ -f "${MARKER_FILE}" ]; then
    echo "Marker file found:"
    cat "${MARKER_FILE}"
    source "${MARKER_FILE}"
fi

if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
    #apk add --no-cache bash 

    echo "**** get pnpm ****"
    # https://github.com/pnpm/pnpm/releases/download/v8.7.5/pnpm-linuxstatic-x64
    curl -fsSL "https://github.com/pnpm/pnpm/releases/download/v${PNPM_VERSION}/pnpm-linuxstatic-x64"  --output "/usr/bin/pnpm" --compressed
    chmod 755 /usr/bin/pnpm
    mkdir -p "${PNPM_HOME}"
    chown -R :$USER_GID "${PNPM_HOME}"
    chmod -R 775 "${PNPM_HOME}"
    chmod -R a+rwx "${PNPM_HOME}"
    echo -e "export PNPM_HOME=$PNPM_HOME\n\
    export PATH=\$PNPM_HOME:\$PATH" | tee /etc/profile.d/pnpm.sh
    chmod +x /etc/profile.d/pnpm.sh
    export PNPM_HOME="${PNPM_HOME}"
    SHELL="/bin/bash" /usr/bin/pnpm setup --force

    PACKAGES_ALREADY_INSTALLED="true"
fi


# Write marker file
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}" > "${MARKER_FILE}"

echo "Done!"
