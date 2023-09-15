#!/bin/ash

set -e

FNM_VERSION=${1:-"1.35.1"}
FNM_DIR=${2:-"/opt/fnm"}
USER_GID=${3:-"1000"}
SWITCHED_TO_BASH=${4:-"true"}
MARKER_FILE="/usr/local/etc/vscode-dev-containers/fnm"

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

    apk add --no-cache --update curl zip unzip libstdc++ libgcc
    echo "**** get fnm ****"
    #https://github.com/vanaware/fnm-alpine/releases/download/v1.35.1/fnm-alpine.zip
    curl -fsSL "https://github.com/vanaware/fnm-alpine/releases/download/v${FNM_VERSION}/fnm-alpine.zip"  --output fnm.zip --compressed
    unzip -q fnm.zip -d /usr/bin/
    chmod +x "/usr/bin/fnm" 

    mkdir -p "${FNM_DIR}"
    chown -R :$USER_GID "${FNM_DIR}"
    chmod -R 775 "${FNM_DIR}"
    chmod -R a+rwx "${DENO_DIR}"

    echo -e "export FNM_DIR=$FNM_DIR\n\
    eval \"\`FNM_DIR=\$FNM_DIR fnm env\`\"" | tee /etc/profile.d/fnm.sh
    chmod +x /etc/profile.d/fnm.sh
    
    PACKAGES_ALREADY_INSTALLED="true"
fi

if [ "${PACKAGES_ALREADY_DELETED}" != "true" ]; then
    
    echo "**** cleanup ****"
    apk del --purge
    rm -f fnm.zip

    PACKAGES_ALREADY_DELETED="true"
fi

# Write marker file
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}\n\
    PACKAGES_ALREADY_DELETED=${PACKAGES_ALREADY_DELETED}" > "${MARKER_FILE}"
echo "Done!"
