# syntax=docker/dockerfile:1.7
#
# Build an independent BioEmu image from public sources.
#
# This Dockerfile does not depend on bioemu_full or bioemu_full_slim. It starts
# from an NVIDIA CUDA runtime, installs BioEmu from PyPI, and can optionally
# pre-download the model, ColabFold, and HPacker assets during the build.

FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.10
ARG BIOEMU_MODEL=bioemu-v1.2
ARG PRELOAD_BIOEMU_MODEL=1
ARG PRELOAD_COLABFOLD=1
ARG PREINSTALL_HPACKER=1

ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:/opt/conda/condabin:$PATH \
    BIOEMU_MODEL=${BIOEMU_MODEL} \
    BIOEMU_HOME=/opt/bioemu \
    BIOEMU_PRETRAINED_DIR=/opt/bioemu/pretrained \
    BIOEMU_COLABFOLD_DIR=/opt/bioemu/.bioemu_colabfold \
    HF_HOME=/opt/bioemu/.cache/huggingface \
    HPACKER_ENV_NAME=hpacker \
    HPACKER_VENV_DIR=/opt/bioemu/hpacker_venv \
    HPACKER_REPO_DIR=/opt/bioemu/hpacker-src \
    JAX_PLATFORMS=cpu \
    XLA_PYTHON_CLIENT_PREALLOCATE=false \
    TF_FORCE_GPU_ALLOW_GROWTH=true \
    MPLCONFIGDIR=/tmp/mpl \
    TMPDIR=/tmp \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      bzip2 \
      ca-certificates \
      curl \
      git \
      libgl1 \
      libglib2.0-0 \
      libgomp1 \
      libsm6 \
      libstdc++6 \
      libxext6 \
      libxrender1 \
      patch \
      wget \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/miniforge.sh \
      https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
    && bash /tmp/miniforge.sh -b -p "${CONDA_DIR}" \
    && rm -f /tmp/miniforge.sh \
    && conda install -y -c conda-forge "python=${PYTHON_VERSION}" pip \
    && conda clean -afy

COPY requirements.txt /tmp/requirements.txt

RUN python -m pip install --upgrade pip setuptools wheel uv \
    && python -m pip install --no-cache-dir -r /tmp/requirements.txt \
    && python -m pip cache purge || true

RUN mkdir -p \
      "${BIOEMU_HOME}/pretrained" \
      "${BIOEMU_HOME}/cache/so3" \
      "${BIOEMU_HOME}/.cache" \
      "$(dirname "${HPACKER_REPO_DIR}")" \
      /tmp/mpl

RUN <<'BASH'
set -euo pipefail
if [[ "${PRELOAD_BIOEMU_MODEL}" == "1" ]]; then
  python - <<'PY'
import os
import shutil
from huggingface_hub import hf_hub_download

model = os.environ.get("BIOEMU_MODEL", "bioemu-v1.2")
target = os.path.join(os.environ["BIOEMU_PRETRAINED_DIR"], model)
os.makedirs(target, exist_ok=True)
for name in ("checkpoint.ckpt", "config.yaml"):
    cached = hf_hub_download(
        repo_id="microsoft/bioemu",
        filename=f"checkpoints/{model}/{name}",
    )
    shutil.copy2(cached, os.path.join(target, name))
print(f"Preloaded {model} into {target}")
PY
fi
BASH

RUN <<'BASH'
set -euo pipefail
if [[ "${PRELOAD_COLABFOLD}" == "1" ]]; then
  python - <<'PY'
import os
import subprocess
from pathlib import Path

try:
    from bioemu.get_embeds import ensure_colabfold_install
except Exception as exc:
    print(f"BioEmu has no separate ColabFold installer to run: {exc!r}")
else:
    bin_dir = Path(ensure_colabfold_install())
    cf_python = bin_dir / "python"
    data_dir = Path(os.environ["BIOEMU_HOME"]) / ".cache" / "colabfold"
    subprocess.check_call([
        str(cf_python),
        "-c",
        (
            "from pathlib import Path; "
            "from colabfold.download import download_alphafold_params; "
            f"download_alphafold_params('alphafold2', Path({str(data_dir)!r}))"
        ),
    ])
    print(f"Preloaded ColabFold AlphaFold2 params into {data_dir}")
PY
fi
BASH

RUN <<'BASH'
set -euo pipefail
if [[ "${PREINSTALL_HPACKER}" == "1" ]]; then
  python - <<'PY'
import inspect
import os

from bioemu.hpacker_setup.setup_hpacker import ensure_hpacker_install

kwargs = {}
signature = inspect.signature(ensure_hpacker_install)
if "envname" in signature.parameters:
    kwargs["envname"] = os.environ.get("HPACKER_ENV_NAME", "hpacker")
if "venv_dir" in signature.parameters:
    kwargs["venv_dir"] = os.environ.get("HPACKER_VENV_DIR", "/opt/bioemu/hpacker_venv")
if "repo_dir" in signature.parameters:
    kwargs["repo_dir"] = os.environ.get("HPACKER_REPO_DIR", "/opt/bioemu/hpacker-src")
ensure_hpacker_install(**kwargs)
print("HPacker setup completed")
PY
fi
BASH

RUN <<'BASH'
set -euo pipefail
cat > /usr/local/bin/bioemu-sample-local <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

MODEL="${BIOEMU_MODEL:-bioemu-v1.2}"
PRETRAINED_DIR="${BIOEMU_PRETRAINED_DIR:-/opt/bioemu/pretrained}"
CKPT="${PRETRAINED_DIR}/${MODEL}/checkpoint.ckpt"
CFG="${PRETRAINED_DIR}/${MODEL}/config.yaml"

if [[ -f "${CKPT}" && -f "${CFG}" ]]; then
  exec python -m bioemu.sample "$@" --ckpt_path "${CKPT}" --model_config_path "${CFG}"
fi

exec python -m bioemu.sample "$@" --model_name "${MODEL}"
EOF
cat > /usr/local/bin/bioemu-sidechain-relax <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export HPACKER_ENV_NAME="${HPACKER_ENV_NAME:-hpacker}"
export HPACKER_VENV_DIR="${HPACKER_VENV_DIR:-/opt/bioemu/hpacker_venv}"
export HPACKER_REPO_DIR="${HPACKER_REPO_DIR:-/opt/bioemu/hpacker-src}"

exec python -m bioemu.sidechain_relax "$@"
EOF
chmod +x /usr/local/bin/bioemu-sample-local /usr/local/bin/bioemu-sidechain-relax
BASH

RUN useradd --create-home --shell /bin/bash bioemu \
    && chown -R bioemu:bioemu "${BIOEMU_HOME}" /home/bioemu /tmp/mpl \
    && conda clean -afy \
    && rm -rf /root/.cache/pip /tmp/* \
    && mkdir -p /tmp/mpl \
    && chown bioemu:bioemu /tmp/mpl

USER bioemu
WORKDIR /work

ENTRYPOINT ["/usr/local/bin/bioemu-sample-local"]
CMD ["--help"]
