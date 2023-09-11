#!/bin/ash

set -e

SPACE_CLI_VERSION=${1:-"0.4.1"}
SPACE_CLI_BASE_URL="https://github.com/deta/space-cli/archive/refs/tags"
SPACE_CLI_SRC_URL="$SPACE_CLI_BASE_URL/v$SPACE_CLI_VERSION.tar.gz"
SPACE_CLI_FOLDER="space-cli-$SPACE_CLI_VERSION"
MARKER_FILE="/usr/local/etc/vscode-dev-containers/space-cli"

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

echo "Installing space-cli v${SPACE_CLI_VERSION}"

# Install go, common dependencies
if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then

    echo "**** get packages go ****"
    apk update
    apk add --no-cache \
        go
    PACKAGES_ALREADY_INSTALLED="true"
fi

if [ "${SRC_DOWNLOADED}" != "true" ]; then

    echo "**** get space ****"
	# curl -sL https://github.com/deta/space-cli/archive/refs/tags/v0.3.2.tar.gz | tar -xzC /tmp 2>&1
	curl -sL "${SPACE_CLI_SRC_URL}" | tar -xzC /tmp 2>&1
    SRC_DOWNLOADED="true"
fi

if [ "${SRC_DOWNLOADED}" = "true" ] && [ "${SRC_INSTALLED}" != "true" ]; then
	
    echo "**** setup space ****"
	# cd /tmp/space-cli-0.3.2
	cd "/tmp/${SPACE_CLI_FOLDER}"
	
	# test it
	# go run main.go version
	
	# Build the space binary
	# go build -C "/tmp/${SPACE_CLI_FOLDER}" <= when using go version >1.20
	go build -ldflags="-X github.com/deta/space/cmd/shared.SpaceVersion=${SPACE_CLI_VERSION} -X github.com/deta/space/cmd/shared.Platform=amd64-linux"
	
	# Install the space binary to your $GOPATH/bin
	# go install
	
    echo "**** finalize setup ****"
	# make available even after uninstalling go package
	mv space /usr/local/bin/
	
    SRC_INSTALLED="true"
fi

if [ "${SRC_DELETED}" != "true" ]; then

    echo "**** cleanup ****"
    apk del --purge
	apk del go
	cd ~/
    rm -rf "/tmp/${SPACE_CLI_FOLDER}"
    SRC_DELETED="true"
fi

# Write marker file
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
	PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}\n\
    SRC_DOWNLOADED=${SRC_DOWNLOADED}\n\
	SRC_INSTALLED=${SRC_INSTALLED}\n\
    SRC_DELETED=${SRC_DELETED}" > "${MARKER_FILE}"

echo "Done!"