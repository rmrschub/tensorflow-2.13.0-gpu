ARG BASE_IMAGE=tensorflow/tensorflow:2.13.0-gpu

FROM $BASE_IMAGE

LABEL org.opencontainers.image.authors="René Schubotz"
LABEL org.opencontainers.image.source="https://github.com/rmrschub/tensorflow-2.13.0-gpu"

ARG NB_USER
ARG NB_GROUP
ARG NB_UID
ARG NB_PREFIX
ARG HOME

ENV NB_USER ${NB_USER:-jovyan}
ENV NB_GROUP ${NB_GROUP:-users}
ENV NB_UID ${NB_UID:-1000}
ENV NB_PREFIX ${NB_PREFIX:-/}
ENV HOME /home/$NB_USER
ENV SHELL /bin/bash

# set shell to bash
SHELL ["/bin/bash", "-c"]

# Workaround
# https://github.com/NVIDIA/nvidia-docker/issues/1632#issuecomment-1135513277
RUN set -ex; \
    apt-key del 7fa2af80; \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub; \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64/7fa2af80.pub;

# From https://github.com/kubeflow/kubeflow/blob/master/components/example-notebook-servers/base/Dockerfile
# install - usefull linux packages
RUN set -ex; \
    \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -yq; \
    apt-get install -yq --no-install-recommends \
        sudo \
        htop \
        rsync \
        openssh-client \
        apt-transport-https \
        bash \
        bash-completion \
        bzip2 \
        ca-certificates \
        curl \
        git \
        less \
        gnupg \
        gnupg2 \
        locales \
        nano \
        tzdata \
        unzip \
        vim \
        wget \
        zip; \
        \
    if command -v python3 >/dev/null 2>&1; then \
        if ! python3 -Im ensurepip --version; then \
            apt-get install -yq --no-install-recommends python3-venv; \
        fi; \
    fi; \
    \
    # create user and set required ownership
    useradd -M -s "$SHELL" -N -u ${NB_UID} ${NB_USER}; \
    if [[ -n "$HOME" && ! -d "$HOME" ]]; then \
        mkdir -p "${HOME}"; \
        chown "$NB_USER:$NB_GROUP" -R "$HOME"; \
    fi; \
    if [[ ! -f /etc/sudoers ]] || ! grep -q "^${NB_USER}[[:space:]]" /etc/sudoers; then \
        if [[ ! -f /etc/sudoers ]]; then \
            touch /etc/sudoers; \
        fi; \
        chmod 0660 /etc/sudoers; \
        echo "${NB_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers; \
        chmod 0440 /etc/sudoers; \
    fi; \
    \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

# set locale configs
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

COPY requirements.txt /tmp/requirements.txt
RUN set -ex; \
    \
    pip install -r /tmp/requirements.txt; 

USER $NB_USER