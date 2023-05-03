#!/bin/ash

set -e

ALPINE_GLIBC_PACKAGE_VERSION=${1:-"2.35-r1"}
LANG=${2:-"C.UTF-8"}

ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download"
ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk"
ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk"
ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk"
MARKER_FILE="/usr/local/etc/vscode-dev-containers/glibc"

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

# Add sgerrand gpg Keys
if [ "${GPG_ALREADY_ADDED}" != "true" ]; then
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub"
    GPG_ALREADY_ADDED="true"
fi

# Download packages
if [ "${PACKAGES_ALREADY_DOWNLOADED}" != "true" ]; then
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates
    wget "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME"
    wget "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME"
    wget "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"
    PACKAGES_ALREADY_DOWNLOADED="true"
fi

# Install packages
if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
    mv /etc/nsswitch.conf /etc/nsswitch.conf.bak
    apk add --no-cache --force-overwrite \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"
    mv /etc/nsswitch.conf.bak /etc/nsswitch.conf        
    apk fix --force-overwrite alpine-baselayout-data
    (/usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true) && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    chmod +x /etc/profile.d/locale.sh
    PACKAGES_ALREADY_INSTALLED="true"
fi


if [ "${GPG_ALREADY_DELETED}" != "true" ]; then
    rm "/etc/apk/keys/sgerrand.rsa.pub" 
    GPG_ALREADY_DELETED="true"
fi

if [ "${PACKAGES_ALREADY_DELETED}" != "true" ]; then
    apk del glibc-i18n 
    rm "/root/.wget-hsts"
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" 

    PACKAGES_ALREADY_DELETED="true"
fi

# Write marker file
mkdir -p "$(dirname "${MARKER_FILE}")"
echo -e "\
    GPG_ALREADY_ADDED=${GPG_ALREADY_ADDED}\n\
    PACKAGES_ALREADY_INSTALLED=${PACKAGES_ALREADY_INSTALLED}\n\
    PACKAGES_ALREADY_DOWNLOADED=${PACKAGES_ALREADY_DOWNLOADED}\n\
    PACKAGES_ALREADY_DELETED=${PACKAGES_ALREADY_DELETED}\n\
    GPG_ALREADY_DELETED=${GPG_ALREADY_DELETED}" > "${MARKER_FILE}"

echo "Done!"