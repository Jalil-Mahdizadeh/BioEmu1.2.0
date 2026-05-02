#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"

if [[ "${BIOEMU_TEST_REQUIRE_GPU:-1}" == "1" ]]; then
  python - <<'PY'
import sys
import torch

if not torch.cuda.is_available():
    sys.exit("CUDA is not available. Start the container with GPU access or set BIOEMU_TEST_REQUIRE_GPU=0.")

print(f"CUDA device: {torch.cuda.get_device_name(0)}")
PY
fi

export BIOEMU_SEQUENCE="${BIOEMU_TEST_SEQUENCE:-${ROOT_DIR}/test/data/test_sequence.a3m}"
export BIOEMU_NUM_SAMPLES="${BIOEMU_TEST_NUM_SAMPLES:-5}"
export BIOEMU_OUTPUT_DIR="${BIOEMU_TEST_SAMPLE_OUT:-${ROOT_DIR}/test/output/sampling-5}"
export BIOEMU_BATCH_SIZE_100="${BIOEMU_TEST_BATCH_SIZE_100:-5}"
export BIOEMU_EXTRA_ARGS="${BIOEMU_EXTRA_ARGS:---filter_samples False --base_seed 101}"

bash "${ROOT_DIR}/run_bioemu1.2_sampling.sh"

test -s "${BIOEMU_OUTPUT_DIR}/topology.pdb"
test -s "${BIOEMU_OUTPUT_DIR}/samples.xtc"
echo "Sampling smoke test wrote ${BIOEMU_OUTPUT_DIR}"
