#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# EDIT THIS SECTION
# ============================================================

WORKSPACE="/workspace"
SAMPLE_DIR="${WORKSPACE}/test/output/sampling-5"
INPUT_DIR="${WORKSPACE}/test/output/sidechain-input"
OUTPATH="${WORKSPACE}/test/output/sidechain-cpu"
PREFIX="smoke"

# CPU by default for this test.
CUDA_VISIBLE_DEVICES=""

# Side-chain reconstruction only.
MD_EQUIL=0
MD_PROTOCOL="local_minimization"
SIMTIME_NS=0

# ============================================================
# DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU ARE CHANGING
# ============================================================

if [[ ! -s "${SAMPLE_DIR}/topology.pdb" || ! -s "${SAMPLE_DIR}/samples.xtc" ]]; then
  echo "Missing sampling output in ${SAMPLE_DIR}."
  echo "Run: bash ./test/run_5_sampling_gpu.sh"
  exit 1
fi

export CUDA_VISIBLE_DEVICES
export TMPDIR="${WORKSPACE}/tmp"
export MPLCONFIGDIR="${WORKSPACE}/mpl"

mkdir -p "${INPUT_DIR}" "${OUTPATH}" "${TMPDIR}" "${MPLCONFIGDIR}"

python - <<PY
from pathlib import Path
import mdtraj as md

sample_dir = Path(${SAMPLE_DIR@Q})
out_dir = Path(${INPUT_DIR@Q})

traj = md.load_xtc(str(sample_dir / "samples.xtc"), top=str(sample_dir / "topology.pdb"))
one_frame = traj[0]
one_frame.save_xtc(str(out_dir / "one_frame.xtc"))
one_frame.save_pdb(str(out_dir / "topology.pdb"))
print(f"Wrote one-frame side-chain input with {one_frame.n_atoms} atoms")
PY

args=(
  bioemu-sidechain-relax
  --pdb-path "${INPUT_DIR}/topology.pdb"
  --xtc-path "${INPUT_DIR}/one_frame.xtc"
  --outpath "${OUTPATH}"
  --prefix "${PREFIX}"
  --simtime-ns "${SIMTIME_NS}"
)

if [[ "${MD_EQUIL}" == "1" ]]; then
  args+=(--md-equil --md-protocol "${MD_PROTOCOL}")
else
  args+=(--no-md-equil)
fi

"${args[@]}"

test -s "${OUTPATH}/${PREFIX}_sidechain_rec.pdb"
test -s "${OUTPATH}/${PREFIX}_sidechain_rec.xtc"
echo "Side-chain smoke test wrote ${OUTPATH}"
