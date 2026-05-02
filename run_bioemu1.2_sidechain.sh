#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Run BioEmu side-chain reconstruction inside an already-running container.

This script does not start Docker. Start or enter a BioEmu container first,
mount this repository as /work, then run this script inside the container.

Environment variables:

  BIOEMU_PDB_PATH
      Backbone topology PDB.
      Default: /work/out/NusA-full-10k/selected-frames/topology.pdb.

  BIOEMU_XTC_PATH
      Backbone trajectory XTC.
      Default: /work/out/NusA-full-10k/selected-frames/selected_frames.xtc.

  BIOEMU_SIDECHAIN_OUTPATH
      Output directory.
      Default: /work/out/NusA-full-10k/selected-frames/sidechain.

  BIOEMU_SIDECHAIN_PREFIX
      Output filename prefix.
      Default: NusA.

  BIOEMU_MD_EQUIL
      1 to run OpenMM minimization/equilibration, 0 for side chains only.
      Default: 1.

  BIOEMU_MD_PROTOCOL
      local_minimization or md_equil.
      Default: local_minimization.

  BIOEMU_SIMTIME_NS
      Optional unconstrained MD time in ns.
      Default: 0.

  BIOEMU_SIDECHAIN_CMD
      Side-chain command to run.
      Default: bioemu-sidechain-relax if available, otherwise python -m bioemu.sidechain_relax.

  BIOEMU_SIDECHAIN_EXTRA_ARGS
      Extra arguments passed directly to the side-chain command.

Example:

  BIOEMU_MD_EQUIL=0 \
  BIOEMU_PDB_PATH=/work/out/example-5/topology.pdb \
  BIOEMU_XTC_PATH=/work/out/example-5/samples.xtc \
  BIOEMU_SIDECHAIN_OUTPATH=/work/out/example-5/sidechain \
  BIOEMU_SIDECHAIN_PREFIX=example \
  bash ./run_bioemu1.2_sidechain.sh
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

PDB_PATH="${BIOEMU_PDB_PATH:-/work/out/NusA-full-10k/selected-frames/topology.pdb}"
XTC_PATH="${BIOEMU_XTC_PATH:-/work/out/NusA-full-10k/selected-frames/selected_frames.xtc}"
OUTPATH="${BIOEMU_SIDECHAIN_OUTPATH:-/work/out/NusA-full-10k/selected-frames/sidechain}"
PREFIX="${BIOEMU_SIDECHAIN_PREFIX:-NusA}"
MD_EQUIL="${BIOEMU_MD_EQUIL:-1}"
MD_PROTOCOL="${BIOEMU_MD_PROTOCOL:-local_minimization}"
SIMTIME_NS="${BIOEMU_SIMTIME_NS:-0}"

export TMPDIR="${TMPDIR:-/work/tmp}"
export MPLCONFIGDIR="${MPLCONFIGDIR:-/work/mpl}"

mkdir -p "${OUTPATH}" "${TMPDIR}" "${MPLCONFIGDIR}"

if [[ -n "${BIOEMU_SIDECHAIN_CMD:-}" ]]; then
  read -r -a SIDECHAIN_CMD <<< "${BIOEMU_SIDECHAIN_CMD}"
elif command -v bioemu-sidechain-relax >/dev/null 2>&1; then
  SIDECHAIN_CMD=(bioemu-sidechain-relax)
else
  SIDECHAIN_CMD=(python -m bioemu.sidechain_relax)
fi

md_args=(--md-protocol "${MD_PROTOCOL}")
if [[ "${MD_EQUIL}" == "0" || "${MD_EQUIL}" == "false" || "${MD_EQUIL}" == "False" ]]; then
  md_args=(--no-md-equil)
else
  md_args=(--md-equil --md-protocol "${MD_PROTOCOL}")
fi

EXTRA_ARGS=()
if [[ -n "${BIOEMU_SIDECHAIN_EXTRA_ARGS:-}" ]]; then
  read -r -a EXTRA_ARGS <<< "${BIOEMU_SIDECHAIN_EXTRA_ARGS}"
fi

"${SIDECHAIN_CMD[@]}" \
  --pdb-path "${PDB_PATH}" \
  --xtc-path "${XTC_PATH}" \
  --outpath "${OUTPATH}" \
  --prefix "${PREFIX}" \
  "${md_args[@]}" \
  --simtime-ns "${SIMTIME_NS}" \
  "${EXTRA_ARGS[@]}"
