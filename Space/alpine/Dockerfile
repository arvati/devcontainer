# [Choice] Alpine version: 3.17, 3.16, 3.15, 3.14, 3.13, 3.12, 3.11
#ARG VARIANT=3.17
#FROM alpine:${VARIANT}
#FROM alpine:3.17
FROM frolvlad/alpine-glibc:alpine-3.17

ENV NODE_VERSION 18.14.2

# [Option] Install zsh
ARG INSTALL_ZSH="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID


COPY library-scripts/*.sh library-scripts/*.env /tmp/library-scripts/
RUN apk update && ash /tmp/library-scripts/common-alpine.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" 

# Install alpine-pkg-glibc from https://github.com/sgerrand/alpine-pkg-glibc
# Code from https://github.com/Docker-Hub-frolvlad/docker-alpine-glibc/blob/master/Dockerfile

ARG GLIBC_VERSION="2.35-r1"
ENV LANG=C.UTF-8
#RUN apk update && ash /tmp/library-scripts/glibc-alpine.sh "${GLIBC_VERSION}" "${LANG}" 

# Install deta space cli from https://github.com/deta/space-cli

ARG SPACE_CLI_VERSION="0.4.1"
RUN apk update && ash /tmp/library-scripts/deta-space-cli-alpine.sh "${SPACE_CLI_VERSION}"

ARG CONDA_VERSION="py39_23.1.0-1"
ARG CONDA_SHA256="5dc619babc1d19d6688617966251a38d245cb93d69066ccde9a013e1ebb5bf18"
ARG CONDA_DIR="/opt/conda"
ENV PATH="$CONDA_DIR/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1

RUN apk update && ash /tmp/library-scripts/miniconda-alpine.sh "${CONDA_VERSION}" "${CONDA_SHA256}" "${CONDA_DIR}"


RUN apk update \
    && apk add --no-cache --update nodejs npm yarn openssl

	
ARG NPM_GLOBAL=/usr/local/share/npm-global
# Add NPM global to PATH.
ENV PATH=${NPM_GLOBAL}/bin:${PATH}

ARG NODE_MODULES="eslint typescript"

RUN \
	umask 0002 \
    && mkdir -p ${NPM_GLOBAL} \
    && touch /etc/npmrc \
    && chown ${USER_UID}:${USER_GID} ${NPM_GLOBAL} /etc/npmrc \
    && chmod g+s ${NPM_GLOBAL} \
    && npm config -g set prefix ${NPM_GLOBAL} \
    && su ${USERNAME} -c "npm config -g set prefix ${NPM_GLOBAL}" \
    # Install eslint
    && su ${USERNAME} -c "umask 0002 && npm install -g ${NODE_MODULES}" \
    && npm cache clean --force > /dev/null 2>&1

	
# Clean up
RUN rm -rf /tmp/library-scripts

#COPY docker-entrypoint.sh /usr/local/bin/

USER $USERNAME
ENV  USER=$USERNAME HOME=/home/$USERNAME
WORKDIR /home/$USERNAME

SHELL [ "/bin/bash", "--login", "-c" ]
#ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "/bin/bash" ]

