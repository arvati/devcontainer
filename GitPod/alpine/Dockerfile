# [Choice] Alpine version: 3.17, 3.16, 3.15, 3.14, 3.13, 3.12, 3.11
#ARG VARIANT=3.17
#FROM alpine:${VARIANT}
FROM alpine:3.17 as alpine-glibc

# Install alpine-pkg-glibc from https://github.com/sgerrand/alpine-pkg-glibc
# Code from https://github.com/Docker-Hub-frolvlad/docker-alpine-glibc/blob/master/Dockerfile

ARG GLIBC_VERSION="2.34-r0"
ENV LANG=C.UTF-8
COPY library-scripts/*.sh library-scripts/*.env /tmp/library-scripts/
RUN apk update && ash /tmp/library-scripts/glibc-alpine.sh "${GLIBC_VERSION}" "${LANG}" 


FROM alpine-glibc

# [Option] Install zsh
ARG INSTALL_ZSH="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=gitpod
ARG USER_UID=33333
ARG USER_GID=$USER_UID


COPY library-scripts/*.sh library-scripts/*.env /tmp/library-scripts/
RUN apk update && ash /tmp/library-scripts/common-alpine.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" 

# Install deta space cli from https://github.com/deta/space-cli

ARG SPACE_CLI_VERSION="0.4.1"
RUN apk update && ash /tmp/library-scripts/deta-space-cli-alpine.sh "${SPACE_CLI_VERSION}"

ARG MAMBA_VERSION="1.5.1-0"
ARG CONDA_DIR="/opt/conda"
RUN apk update && ash /tmp/library-scripts/micromamba-alpine.sh "${MAMBA_VERSION}" "${CONDA_DIR}" "${USER_GID}"

ARG DENO_VERSION="1.36.4"
ARG DENO_DIR="/opt/deno"
RUN apk update && ash /tmp/library-scripts/deno-alpine.sh "${DENO_VERSION}" "${DENO_DIR}" "${USER_GID}"

ARG PNPM_VERSION="8.7.5"
ARG PNPM_HOME="/opt/pnpm"
RUN apk update && ash /tmp/library-scripts/pnpm-alpine.sh "${PNPM_VERSION}" "${PNPM_HOME}" "${USER_GID}"

ARG FNM_VERSION="1.35.1"
ARG FNM_DIR="/opt/fnm"
RUN apk update && ash /tmp/library-scripts/fnm-alpine.sh "${FNM_VERSION}" "${FNM_DIR}" "${USER_GID}"

RUN \
    apk add openrc openssh openssl \
    && su ${USERNAME} -c 'ssh-keygen -A' \
    && echo -e "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && mkdir -p /run/openrc \
    && touch /run/openrc/softlevel \
    && mkdir /workspace && chown -hR ${USERNAME}:${USERNAME} /workspace
	
# Clean up
RUN rm -rf /tmp/library-scripts

#COPY docker-entrypoint.sh /usr/local/bin/

USER $USERNAME
ENV  USER=$USERNAME HOME=/home/$USERNAME
WORKDIR /home/$USERNAME

SHELL [ "/bin/bash", "--login", "-c" ]
#ENTRYPOINT ["docker-entrypoint.sh"]
#ENTRYPOINT ["sh", "-c", "rc-status; rc-service sshd start"]

CMD [ "/bin/bash" ]

