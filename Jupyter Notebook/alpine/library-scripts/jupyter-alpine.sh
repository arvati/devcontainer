#!/bin/ash

set -e

CONDA_DIR=${1:-"/opt/conda"}
SWITCHED_TO_BASH=${2:-"true"}
MARKER_FILE="/usr/local/etc/vscode-dev-containers/jupyter"

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

if [ "${COMMUNITY_ALREADY_CONFIGURED}" != "true" ]; then

    cat > /etc/apk/repositories << EOF; $(echo)

https://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main/
https://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community/
https://dl-cdn.alpinelinux.org/alpine/edge/testing/

EOF
    apk update
    COMMUNITY_ALREADY_CONFIGURED="true"
fi   

if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
    
    apk add --no-cache --update-cache \
        python3-dev python3 \
        ipython \
        py3-setuptools \
        py3-pip \
        py3-dotenv \
        py3-numpy \
        py3-pandas \
        geos \
        gfortran \
        musl-dev \
        g++ gcc build-base \
        freetype-dev libpng-dev openblas-dev


    PACKAGES_ALREADY_INSTALLED="true"
fi

if [ "${ENVIRONMENT_ALREADY_INSTALLED}" != "true" ]; then
    
    $CONDA_DIR/bin/conda init bash
    
    # Update Python environment based on environment.yml (if present)
    if [ -f "/tmp/conda-tmp/environment.yml" ]; then 
        $CONDA_DIR/bin/conda env update -n base -vv -f /tmp/conda-tmp/environment.yml
    fi

    ENVIRONMENT_ALREADY_INSTALLED="true"
fi   

if [ "${XPYTHON_ALREADY_INSTALLED}" != "true" ]; then
    
    # Install xpython
    $CONDA_DIR/bin/conda update xeus-python notebook \
    #    jupyter geopandas pygeos numpy-financial chart-studio cufflinks-py python-dotenv kaggle \
        -n base -c conda-forge --override-channels -y --quiet

    XPYTHON_ALREADY_INSTALLED="true"
fi 


 if [ "${NODE_ALREADY_CONFIGURED}" != "true" ]; then
    
    # Config Node
    npm config set user
    npm config set unsafe-perm true
    npm i -g vscode-dts

    NODE_ALREADY_CONFIGURED="true"
fi 


# Write marker file
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}\n\
    XPYTHON_ALREADY_INSTALLED=${XPYTHON_ALREADY_INSTALLED}\n\
    NODE_ALREADY_CONFIGURED=${NODE_ALREADY_CONFIGURED}\n\
    COMMUNITY_ALREADY_CONFIGURED=${COMMUNITY_ALREADY_CONFIGURED}\n\
    ENVIRONMENT_ALREADY_INSTALLED=${ENVIRONMENT_ALREADY_INSTALLED}" > "${MARKER_FILE}"

echo "Done!"
