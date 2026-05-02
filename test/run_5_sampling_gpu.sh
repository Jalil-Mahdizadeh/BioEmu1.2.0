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
export JAX_PLATFORMS="cpu"
export XLA_PYTHON_CLIENT_PREALLOCATE="false"
export TF_FORCE_GPU_ALLOW_GROWTH="true"

mkdir -p "${OUTPUT_DIR}" "${CACHE_EMBEDS_DIR}" "${CACHE_SO3_DIR}" "${TMPDIR}" "${MPLCONFIGDIR}"

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
