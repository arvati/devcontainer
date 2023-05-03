# [Choice] Alpine version: 3.17, 3.16, 3.15, 3.14, 3.13, 3.12, 3.11
#ARG VARIANT=3.17
#FROM alpine:${VARIANT}
FROM alpine:3.17

ENV DENO_VERSION 18.14.2

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
RUN apk update && ash /tmp/library-scripts/glibc-alpine.sh "${GLIBC_VERSION}" "${LANG}" 

RUN apk update \
    && apk add --no-cache --update tini openssl curl zip unzip

ARG DENO_VERSION="1.33.1"
RUN curl -fsSL https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip \
    --output deno.zip \
  && unzip -q deno.zip -d /bin/ \
  && rm deno.zip \
  && chmod 755 /bin/deno
	
# Clean up
RUN rm -rf /tmp/library-scripts

#COPY docker-entrypoint.sh /usr/local/bin/

USER $USERNAME
ENV  USER=$USERNAME HOME=/home/$USERNAME
WORKDIR /home/$USERNAME

SHELL [ "/bin/bash", "--login", "-c" ]
#ENTRYPOINT ["docker-entrypoint.sh"]
ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "/bin/bash" ]

