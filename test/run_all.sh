#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/run_5_sampling_gpu.sh"
bash "${SCRIPT_DIR}/run_one_sidechain_cpu.sh"
