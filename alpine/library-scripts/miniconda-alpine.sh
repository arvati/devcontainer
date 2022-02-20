set -e

CONDA_VERSION=${1:-"py39_4.11.0"}
CONDA_SHA256=${2:-"4ee9c3aa53329cd7a63b49877c0babb49b19b7e5af29807b793a76bdb1d362b4"}
CONDA_DIR=${3:-"/opt/conda"}
SWITCHED_TO_BASH=${4:-"true"}

SCRIPT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
MARKER_FILE="/usr/local/etc/vscode-dev-containers/miniconda"

# Switch to bash right away
if [ "${SWITCHED_TO_BASH}" != "true" ]; then
    apk add bash
    export SWITCHED_TO_BASH=true
    exec /bin/bash "$0" "$@"
    exit $?
fi

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

    echo "**** get Miniconda ****"
    mkdir -p "$CONDA_DIR"
    wget "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" -O miniconda.sh

    if [[ $(sha256sum miniconda.sh) = "$CONDA_SHA256  miniconda.sh" ]];then 

        echo "**** install Miniconda ****"
        bash miniconda.sh -f -b -p "$CONDA_DIR"
        echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh
        chmod +x /etc/profile.d/conda.sh

        echo "$CONDA_DIR/bin/conda activate base" >> /etc/profile.d/base.sh
        chmod +x /etc/profile.d/base.sh

        echo ". /etc/profile.d/base.sh" >> ~/.bashrc

        echo "**** setup Miniconda ****"
        conda update --all --yes
        conda config --set auto_update_conda False

        echo "**** finalize setup ****"
        mkdir -p "$CONDA_DIR/locks"
        chmod 777 "$CONDA_DIR/locks"

        PACKAGES_ALREADY_INSTALLED="true"
    fi
fi

if [ "${PACKAGES_ALREADY_DELETED}" != "true" ]; then
    
    echo "**** cleanup ****"
    apk del --purge
    rm -f miniconda.sh
    conda clean --all --force-pkgs-dirs --yes
    find "$CONDA_DIR" -follow -type f \( -iname "*.a" -o -iname "*.pyc" -o -iname "*.js.map" \) -delete

    PACKAGES_ALREADY_DELETED="true"
fi

# Write marker file
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}\n\
    PACKAGES_ALREADY_DELETED=${PACKAGES_ALREADY_DELETED}" > "${MARKER_FILE}"

echo "Done!"
