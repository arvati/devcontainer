# [Choice] Alpine version: 3.15, 3.14, 3.13, 3.12, 3.11
ARG VARIANT=3.15
FROM alpine:${VARIANT}

# [Option] Install zsh
ARG INSTALL_ZSH="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Copy environment.yml (if found) to a temp locaition so we update the environment. Also
# copy "noop.txt" so the COPY instruction does not fail if no environment.yml exists.
COPY environment.yml* noop.txt /tmp/conda-tmp/

COPY library-scripts/*.sh library-scripts/*.env /tmp/library-scripts/
RUN apk update && ash /tmp/library-scripts/common-alpine.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" 

# Install alpine-pkg-glibc from https://github.com/sgerrand/alpine-pkg-glibc
# Code from https://github.com/Docker-Hub-frolvlad/docker-alpine-glibc/blob/master/Dockerfile

ARG GLIBC_VERSION="2.34-r0"
ENV LANG=C.UTF-8
RUN apk update && ash /tmp/library-scripts/glibc-alpine.sh "${GLIBC_VERSION}" "${LANG}" 

ARG CONDA_VERSION="py39_4.11.0"
ARG CONDA_SHA256="4ee9c3aa53329cd7a63b49877c0babb49b19b7e5af29807b793a76bdb1d362b4"
ARG CONDA_DIR="/opt/conda"
ENV PATH="$CONDA_DIR/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1

RUN apk update && ash /tmp/library-scripts/miniconda-alpine.sh "${CONDA_VERSION}" "${CONDA_SHA256}" "${CONDA_DIR}"

RUN apk update \
    && apk add --no-cache --update nodejs npm openssl

RUN apk update && ash /tmp/library-scripts/jupyter-alpine.sh "${CONDA_DIR}"


# Clean up
RUN rm -rf /tmp/library-scripts /tmp/conda-tmp

EXPOSE 8888                                           
ENTRYPOINT ["$CONDA_DIR/bin/jupyter", "notebook", "--no-browser","--ip=0.0.0.0","--NotebookApp.token=''","--NotebookApp.password=''"]

SHELL [ "/bin/bash", "--login", "-c" ]
