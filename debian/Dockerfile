FROM continuumio/miniconda3
LABEL maintainer="Ademar Arvati Filho <arvati@hotmail.com>"

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Copy environment.yml (if found) to a temp locaition so we update the environment. Also
# copy "noop.txt" so the COPY instruction does not fail if no environment.yml exists.
COPY environment.yml* noop.txt /tmp/conda-tmp/
COPY library-scripts/common-debian.sh /tmp/library-scripts/

# Configure apt and install packages
USER root
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Verify git, process tools, lsb-release (common in install instructions for CLIs) installed
    && apt-get -y install git openssh-client less iproute2 procps iproute2 lsb-release nodejs \
    #
    # Install pylint
    && /opt/conda/bin/pip install pylint \
    #
    # Update Python environment based on environment.yml (if present)
    && if [ -f "/tmp/conda-tmp/environment.yml" ]; then /opt/conda/bin/conda env update -n base -f /tmp/conda-tmp/environment.yml; fi \
    #
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && bash /tmp/library-scripts/common-debian.sh \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /tmp/library-scripts /tmp/conda-tmp

# Install xpython
RUN opt/conda/bin/conda update xeus-python notebook \
#    jupyter geopandas pygeos numpy-financial chart-studio cufflinks-py python-dotenv kaggle \
    -n base -c conda-forge --override-channels -y --quiet

# Install Node
RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
RUN bash -c 'source /root/.bashrc && nvm install node && npm config set user 0 && npm config set unsafe-perm true && npm i -g vscode-dts'

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# default command will launch JupyterLab server for development
#CMD [ "jupyter", "lab", "--no-browser", "--ip='*'", "--port=8888"]

EXPOSE 8888                                           
ENTRYPOINT ["/opt/conda/bin/jupyter", "notebook", "--no-browser","--ip=0.0.0.0","--NotebookApp.token=''","--NotebookApp.password=''"]

SHELL [ "/bin/bash", "--login", "-c" ]