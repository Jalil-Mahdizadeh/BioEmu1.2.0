#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# EDIT THIS SECTION
# ============================================================

WORKSPACE="/workspace"

# Backbone files from a BioEmu sampling run.
PDB_PATH="${WORKSPACE}/out/example-sampling-10k/topology.pdb"
XTC_PATH="${WORKSPACE}/out/example-sampling-10k/samples.xtc"

# Output settings.
OUTPATH="${WORKSPACE}/out/example-sampling-10k/sidechain"
PREFIX="example"

# Side-chain / MD settings.
# Set MD_EQUIL=0 for side-chain reconstruction only.
# Set MD_EQUIL=1 to also run OpenMM minimization/equilibration.
MD_EQUIL=1
MD_PROTOCOL="local_minimization"   # local_minimization or md_equil
SIMTIME_NS=0

# ============================================================
# DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU ARE CHANGING
# ============================================================

export TMPDIR="${WORKSPACE}/tmp"
export MPLCONFIGDIR="${WORKSPACE}/mpl"

mkdir -p "${OUTPATH}" "${TMPDIR}" "${MPLCONFIGDIR}"

args=(
  bioemu-sidechain-relax
  --pdb-path "${PDB_PATH}"
  --xtc-path "${XTC_PATH}"
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
