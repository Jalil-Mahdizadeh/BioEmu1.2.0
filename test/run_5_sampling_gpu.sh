#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# EDIT THIS SECTION
# ============================================================

WORKSPACE="/workspace"
SEQUENCE="${WORKSPACE}/test/data/test_sequence.a3m"
NUM_SAMPLES=5
BATCH_SIZE_100=5
OUTPUT_DIR="${WORKSPACE}/test/output/sampling-5"
CACHE_EMBEDS_DIR="${WORKSPACE}/embeds"
CACHE_SO3_DIR="${WORKSPACE}/so3"

FILTER_SAMPLES="False"
BASE_SEED=101
JAX_PLATFORMS="cpu"
JAX_COMPILATION_CACHE_DIR="${WORKSPACE}/jax_compile_cache"

# ============================================================
# DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU ARE CHANGING
# ============================================================

python - <<'PY'
import sys
import torch

if not torch.cuda.is_available():
    sys.exit("CUDA is not available. Start the container with --gpus all.")

print(f"CUDA device: {torch.cuda.get_device_name(0)}")
PY

export TMPDIR="${WORKSPACE}/tmp"
export MPLCONFIGDIR="${WORKSPACE}/mpl"
export JAX_PLATFORMS
export JAX_COMPILATION_CACHE_DIR
export JAX_PERSISTENT_CACHE_MIN_COMPILE_TIME_SECS="0"
export XLA_PYTHON_CLIENT_PREALLOCATE="false"
export TF_FORCE_GPU_ALLOW_GROWTH="true"

mkdir -p "${OUTPUT_DIR}" "${CACHE_EMBEDS_DIR}" "${CACHE_SO3_DIR}" "${JAX_COMPILATION_CACHE_DIR}" "${TMPDIR}" "${MPLCONFIGDIR}"

echo "Embedding stage: preparing ColabFold embeddings from SEQUENCE with JAX_PLATFORMS=${JAX_PLATFORMS}."
if [[ "${JAX_PLATFORMS}" == "cuda" ]]; then
  echo "CUDA embedding is enabled; the first run can be slow because JAX compiles the model."
else
  echo "Embedding is using CPU; BioEmu sampling will use CUDA after embeddings are ready."
fi

export BIOEMU_SEQUENCE_INPUT="${SEQUENCE}"
export BIOEMU_CACHE_EMBEDS_DIR="${CACHE_EMBEDS_DIR}"

python - <<'PY'
import os

from bioemu.get_embeds import get_colabfold_embeds
from bioemu.seq_io import check_protein_valid, parse_sequence

sequence_input = os.environ["BIOEMU_SEQUENCE_INPUT"]
cache_embeds_dir = os.environ["BIOEMU_CACHE_EMBEDS_DIR"]
msa_file = sequence_input if sequence_input.endswith(".a3m") else None

sequence = parse_sequence(sequence_input)
check_protein_valid(sequence)

print("Preparing embeddings from SEQUENCE.")
get_colabfold_embeds(seq=sequence, cache_embeds_dir=cache_embeds_dir, msa_file=msa_file)
print("Embeddings are ready.")
PY

echo "Sampling stage: starting BioEmu with CUDA available."

bioemu-sample-local \
  "${SEQUENCE}" \
  "${NUM_SAMPLES}" \
  "${OUTPUT_DIR}" \
  --cache_embeds_dir "${CACHE_EMBEDS_DIR}" \
  --cache_so3_dir "${CACHE_SO3_DIR}" \
  --batch_size_100 "${BATCH_SIZE_100}" \
  --filter_samples "${FILTER_SAMPLES}" \
  --base_seed "${BASE_SEED}"

test -s "${OUTPUT_DIR}/topology.pdb"
test -s "${OUTPUT_DIR}/samples.xtc"
echo "Sampling smoke test wrote ${OUTPUT_DIR}"
