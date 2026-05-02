#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# EDIT THIS SECTION
# ============================================================

WORKSPACE="/workspace"

# Protein sequence, FASTA file, or A3M file.
SEQUENCE="TGVVKKVNRDNISLDLGNNAEAVILREDMLPRENFRPGDRVRGVLYSVRPEARGAQLFVTRSKPEMLIELFRIEVPEIGEEVIEIKAAARDPGSRAKIAVKTNDKRIDPVGACVGMRGARVQAVSTELGGERIDIVLWDDNPAQFVINAMAPADVASIVVDEDKHTMDIAVEAGNLAQAIGRNGQNVRLASQLSGWELNVMTVDDLQAKHQAEAHAAIDTFTKYLDIDEDFATVLVEEGFSTLEELAYVPMKELLEIEGLDEPTVEALRERAKNALATIAQAQEESLGDNKPADDLLNLEGVDRDLAFKLAARGVCTLEDLAEQGIDDLADIEGLTDEKAGALIMAARNICWFGDEA"

# Sampling settings.
NUM_SAMPLES=5
BATCH_SIZE_100=5
OUTPUT_DIR="${WORKSPACE}/out/example-sampling-5"
REQUIRE_GPU=1

# Cache folders.
CACHE_EMBEDS_DIR="${WORKSPACE}/embeds"
CACHE_SO3_DIR="${WORKSPACE}/so3"

# BioEmu options.
DENOISER_TYPE="dpm"
FILTER_SAMPLES="True"
BASE_SEED=""          # Empty means random seed.
MSA_HOST_URL=""       # Empty means BioEmu/ColabFold default.
PRECOMPUTE_EMBEDDINGS=1

# ColabFold/JAX embedding generation.
# Use "cuda" with the Dockerfile/Hub image that includes the ColabFold JAX
# GPU stack. If an older image crashes during embedding generation, set this
# to "cpu" and BioEmu sampling will still use the GPU after embeddings finish.
JAX_PLATFORMS="cuda"

# ============================================================
# DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU ARE CHANGING
# ============================================================

export TMPDIR="${WORKSPACE}/tmp"
export MPLCONFIGDIR="${WORKSPACE}/mpl"
export JAX_PLATFORMS
export XLA_PYTHON_CLIENT_PREALLOCATE="false"
export TF_FORCE_GPU_ALLOW_GROWTH="true"

if [[ "${REQUIRE_GPU}" == "1" ]]; then
  python - <<'PY'
import sys
import torch

if not torch.cuda.is_available():
    sys.exit("CUDA is not available. Start Docker with: docker run --gpus all ...")

print(f"BioEmu sampling will use CUDA device: {torch.cuda.get_device_name(0)}")
PY
fi

mkdir -p \
  "${OUTPUT_DIR}" \
  "${CACHE_EMBEDS_DIR}" \
  "${CACHE_SO3_DIR}" \
  "${TMPDIR}" \
  "${MPLCONFIGDIR}"

if [[ "${PRECOMPUTE_EMBEDDINGS}" == "1" ]]; then
  echo "Embedding stage: preparing ColabFold embeddings from SEQUENCE with JAX_PLATFORMS=${JAX_PLATFORMS}."
  echo "GPU use starts in the BioEmu sampling stage after embeddings are ready."

  export BIOEMU_SEQUENCE_INPUT="${SEQUENCE}"
  export BIOEMU_CACHE_EMBEDS_DIR="${CACHE_EMBEDS_DIR}"
  export BIOEMU_MSA_HOST_URL="${MSA_HOST_URL}"

  python - <<'PY'
import os

from bioemu.get_embeds import get_colabfold_embeds
from bioemu.seq_io import check_protein_valid, parse_sequence

sequence_input = os.environ["BIOEMU_SEQUENCE_INPUT"]
cache_embeds_dir = os.environ["BIOEMU_CACHE_EMBEDS_DIR"]
msa_host_url = os.environ.get("BIOEMU_MSA_HOST_URL") or None
msa_file = sequence_input if sequence_input.endswith(".a3m") else None

sequence = parse_sequence(sequence_input)
check_protein_valid(sequence)

print("Preparing embeddings from SEQUENCE.")
print(f"Embedding cache: {cache_embeds_dir}")
get_colabfold_embeds(
    seq=sequence,
    cache_embeds_dir=cache_embeds_dir,
    msa_file=msa_file,
    msa_host_url=msa_host_url,
)
print("Embeddings are ready.")
PY
fi

echo "Sampling stage: starting BioEmu with CUDA available."

args=(
  bioemu-sample-local
  "${SEQUENCE}"
  "${NUM_SAMPLES}"
  "${OUTPUT_DIR}"
  --cache_embeds_dir "${CACHE_EMBEDS_DIR}"
  --cache_so3_dir "${CACHE_SO3_DIR}"
  --batch_size_100 "${BATCH_SIZE_100}"
  --denoiser_type "${DENOISER_TYPE}"
  --filter_samples "${FILTER_SAMPLES}"
)

if [[ -n "${BASE_SEED}" ]]; then
  args+=(--base_seed "${BASE_SEED}")
fi

if [[ -n "${MSA_HOST_URL}" ]]; then
  args+=(--msa_host_url "${MSA_HOST_URL}")
fi

"${args[@]}"
