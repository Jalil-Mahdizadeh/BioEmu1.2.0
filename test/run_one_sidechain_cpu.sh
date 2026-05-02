#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"

SAMPLE_DIR="${BIOEMU_TEST_SAMPLE_DIR:-${ROOT_DIR}/test/output/sampling-5}"
INPUT_DIR="${ROOT_DIR}/test/output/sidechain-input"
SIDECHAIN_OUT="${BIOEMU_TEST_SIDECHAIN_OUT:-${ROOT_DIR}/test/output/sidechain-cpu}"

if [[ ! -s "${SAMPLE_DIR}/topology.pdb" || ! -s "${SAMPLE_DIR}/samples.xtc" ]]; then
  echo "Missing sampling output in ${SAMPLE_DIR}."
  echo "Run: bash ${SCRIPT_DIR}/run_5_sampling_gpu.sh"
  exit 1
fi

mkdir -p "${INPUT_DIR}" "${SIDECHAIN_OUT}"

python - <<PY
from pathlib import Path
import mdtraj as md

sample_dir = Path(${SAMPLE_DIR@Q})
out_dir = Path(${INPUT_DIR@Q})
out_dir.mkdir(parents=True, exist_ok=True)

traj = md.load_xtc(str(sample_dir / "samples.xtc"), top=str(sample_dir / "topology.pdb"))
one_frame = traj[0]
one_frame.save_xtc(str(out_dir / "one_frame.xtc"))
one_frame.save_pdb(str(out_dir / "topology.pdb"))
print(f"Wrote one-frame side-chain input with {one_frame.n_atoms} atoms")
PY

if [[ "${BIOEMU_TEST_SIDECHAIN_USE_GPU:-0}" != "1" ]]; then
  export CUDA_VISIBLE_DEVICES=""
fi

export BIOEMU_PDB_PATH="${INPUT_DIR}/topology.pdb"
export BIOEMU_XTC_PATH="${INPUT_DIR}/one_frame.xtc"
export BIOEMU_SIDECHAIN_OUTPATH="${SIDECHAIN_OUT}"
export BIOEMU_SIDECHAIN_PREFIX="${BIOEMU_TEST_SIDECHAIN_PREFIX:-smoke}"
export BIOEMU_MD_EQUIL="${BIOEMU_TEST_MD_EQUIL:-0}"

bash "${ROOT_DIR}/run_bioemu1.2_sidechain.sh"

test -s "${SIDECHAIN_OUT}/${BIOEMU_SIDECHAIN_PREFIX}_sidechain_rec.pdb"
test -s "${SIDECHAIN_OUT}/${BIOEMU_SIDECHAIN_PREFIX}_sidechain_rec.xtc"
echo "Side-chain smoke test wrote ${SIDECHAIN_OUT}"
