ARG VARIANT=bullseye-backports
FROM debian:${VARIANT}


LABEL maintainer="Ademar Arvati Filho <arvati@hotmail.com>"

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ARG NVM_DIR="/usr/local/share/nvm"
ARG NODE_VERSION="lts"
ARG UPDATE_RC="true"
ARG INSTALL_TOOLS_FOR_NODE_GYP="true"
ARG NVM_VERSION="0.39.1"

ARG POWERSHELL_VERSION="latest"

ARG CARGO_HOME="/usr/local/cargo"
ARG RUSTUP_HOME="/usr/local/rustup"
ARG UPDATE_RUST="false"
ARG RUST_VERSION="latest"
ARG RUSTUP_PROFILE="minimal"

ARG FOUNDRY_VERSION="nightly"
ARG FOUNDRY_DIR="/opt/foundry"

COPY library-scripts/*.sh library-scripts/*.env /tmp/library-scripts/
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends curl ca-certificates \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true"\
    && /bin/bash /tmp/library-scripts/node-debian.sh "${NVM_DIR}" "${NODE_VERSION}" "${USERNAME}" "${UPDATE_RC}" "${INSTALL_TOOLS_FOR_NODE_GYP}" "${NVM_VERSION}"\
    && /bin/bash /tmp/library-scripts/powershell-debian.sh "${POWERSHELL_VERSION}"\
    && /bin/bash /tmp/library-scripts/rust-debian.sh "${CARGO_HOME}" "${RUSTUP_HOME}" "${USERNAME}" "${UPDATE_RC}" "${UPDATE_RUST}" "${RUST_VERSION}" "${RUSTUP_PROFILE}"\
    && /bin/bash /tmp/library-scripts/foundry-debian.sh "${FOUNDRY_VERSION}" "${USERNAME}" "${UPDATE_RC}" "${FOUNDRY_DIR}"\
    #
    # ****************************************************************************
    # * TODO: Add any additional OS packages you want included in the definition *
    # * here. We want to do this before cleanup to keep the "layer" small.       *
    # ****************************************************************************
    # && apt-get -y install --no-install-recommends <your-package-list-here> \
    #
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

USER $USERNAME
ENV  USER=$USERNAME HOME=/home/$USERNAME
WORKDIR /home/$USERNAME
RUN curl -fsSL https://get.deta.dev/cli.sh | sh
RUN npm install --global hardhat-shorthand @remix-project/remixd

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

#EXPOSE 8888                                           
#ENTRYPOINT []

SHELL [ "/bin/bash", "--login", "-c" ]

