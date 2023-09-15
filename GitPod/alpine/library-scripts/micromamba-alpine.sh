#!/bin/ash

set -e

MAMBA_VERSION=${1:-"1.5.1-0"}
CONDA_DIR=${2:-"/opt/conda"}
USER_GID=${3:-"1000"}
SWITCHED_TO_BASH=${4:-"true"}
MARKER_FILE="/usr/local/etc/vscode-dev-containers/micromamba"

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

    echo "**** get Micromamba ****"
    # https://micromamba.snakepit.net/api/micromamba/linux-64/latest
    # https://micromamba.snakepit.net/api/micromamba/linux-64/1.5.1-0
    # https://github.com/mamba-org/micromamba-releases/releases/download/1.5.1-0/micromamba-linux-64
    curl -fsSL "https://github.com/mamba-org/micromamba-releases/releases/download/${MAMBA_VERSION}/micromamba-linux-64"  --output "/usr/bin/micromamba" --compressed
    
    chmod +x "/usr/bin/micromamba" 
    mkdir -p "${CONDA_DIR}/conda-meta"
    chown -R :$USER_GID "${CONDA_DIR}"
    chmod -R 775 "${CONDA_DIR}"
    chmod -R a+rwx "${CONDA_DIR}"
    micromamba shell init --shell=bash --prefix="${CONDA_DIR}/" 

    echo "conda activate base 2>/dev/null || mamba activate base 2>/dev/null  || micromamba activate base" | tee  /etc/profile.d/mamba-base.sh
    chmod +x /etc/profile.d/mamba-base.sh

    echo -e "export MAMBA_ROOT_PREFIX=$CONDA_DIR\n\
    export PATH=\$MAMBA_ROOT_PREFIX/bin:\$PATH" | tee /etc/profile.d/mamba.sh
    chmod +x /etc/profile.d/mamba.sh
    
    # howto install python 3.6 and jupyter on base environment
    #micromamba activate
    #micromamba install python=3.6 jupyter -c conda-forge
    PACKAGES_ALREADY_INSTALLED="true"
fi


# Write marker file
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}" > "${MARKER_FILE}"

echo "Done!"
