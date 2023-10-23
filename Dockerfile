# syntax=docker/dockerfile:1.4

ARG BASE_IMAGE="python:3.10-slim-bookworm"

FROM ${BASE_IMAGE}

ARG GPU_MAKE="nvidia"
ARG EXTRA_ARGS=""
ARG USERNAME="comfyui"
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN \
	--mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
	--mount=target=/var/cache/apt,type=cache,sharing=locked \
	set -eux; \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			git \
			git-lfs \ 
			ffmpeg \
			libsm6 \
			libxext6

RUN set -eux; \
	groupadd --gid ${USER_GID} ${USERNAME}; \
	useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}

# run instructions as user
USER ${USER_UID}:${USER_GID}

WORKDIR /app

ENV PIP_CACHE_DIR="/cache/pip"
ENV VIRTUAL_ENV=/app/venv
ENV TRANSFORMERS_CACHE="/app/.cache/transformers"

# create cache directory
RUN mkdir -p ${TRANSFORMERS_CACHE}

# create virtual environment to manage packages
RUN python -m venv ${VIRTUAL_ENV}

# run python from venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

# copy requirements files first so packages can be cached separately
COPY --chown=${USER_UID}:${USER_GID} requirements-${GPU_MAKE}.txt .
RUN --mount=type=cache,target=/cache/,uid=${USER_UID},gid=${USER_GID} \
	pip install -r requirements-${GPU_MAKE}.txt

COPY --chown=${USER_UID}:${USER_GID} requirements.txt .
RUN --mount=type=cache,target=/cache/,uid=${USER_UID},gid=${USER_GID} \
	pip install -r requirements.txt

COPY --chown=${USER_UID}:${USER_GID} . .

# default environment variables
ENV COMFYUI_ADDRESS=0.0.0.0
ENV COMFYUI_PORT=8188
ENV COMFYUI_EXTRA_ARGS=""
# default start command
CMD python -u main.py --listen ${COMFYUI_ADDRESS} --port ${COMFYUI_PORT} --disable-cuda-malloc ${EXTRA_ARGS} ${COMFYUI_EXTRA_ARGS}