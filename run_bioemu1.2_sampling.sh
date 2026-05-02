#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Run BioEmu v1.2 sampling inside an already-running container.

This script does not start Docker. Start or enter a BioEmu container first,
mount this repository as /work, then run this script inside the container.

Environment variables:

  BIOEMU_SEQUENCE
      Amino-acid sequence, FASTA path, or A3M path.
      Default: NusA SKK-CTD sequence.

  BIOEMU_NUM_SAMPLES
      Total number of samples to produce.
      Default: 10000.

  BIOEMU_OUTPUT_DIR
      Output directory for batches, topology.pdb, and samples.xtc.
      Default: /work/out/NusA-SKK-CTD-10k.

  BIOEMU_BATCH_SIZE_100
      Batch size normalized to a 100-residue sequence.
      Default: 250.

  BIOEMU_CACHE_EMBEDS_DIR
      Cache directory for ColabFold embeddings.
      Default: /work/embeds.

  BIOEMU_CACHE_SO3_DIR
      Cache directory for SO3 precomputations.
      Default: /work/so3.

  BIOEMU_SAMPLE_CMD
      Sampling command to run.
      Default: bioemu-sample-local if available, otherwise python -m bioemu.sample.

  BIOEMU_EXTRA_ARGS
      Extra arguments passed directly to BioEmu sampling.
      Example: --filter_samples False --base_seed 17

Example:

  BIOEMU_NUM_SAMPLES=5 \
  BIOEMU_OUTPUT_DIR=/work/out/example-5 \
  BIOEMU_EXTRA_ARGS="--filter_samples False --base_seed 17" \
  bash ./run_bioemu1.2_sampling.sh
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SEQUENCE="${BIOEMU_SEQUENCE:-TGVVKKVNRDNISLDLGNNAEAVILREDMLPRENFRPGDRVRGVLYSVRPEARGAQLFVTRSKPEMLIELFRIEVPEIGEEVIEIKAAARDPGSRAKIAVKTNDKRIDPVGACVGMRGARVQAVSTELGGERIDIVLWDDNPAQFVINAMAPADVASIVVDEDKHTMDIAVEAGNLAQAIGRNGQNVRLASQLSGWELNVMTVDDLQAKHQAEAHAAIDTFTKYLDIDEDFATVLVEEGFSTLEELAYVPMKELLEIEGLDEPTVEALRERAKNALATIAQAQEESLGDNKPADDLLNLEGVDRDLAFKLAARGVCTLEDLAEQGIDDLADIEGLTDEKAGALIMAARNICWFGDEA}"
NUM_SAMPLES="${BIOEMU_NUM_SAMPLES:-10000}"
OUTPUT_DIR="${BIOEMU_OUTPUT_DIR:-/work/out/NusA-SKK-CTD-10k}"
BATCH_SIZE_100="${BIOEMU_BATCH_SIZE_100:-250}"
CACHE_EMBEDS_DIR="${BIOEMU_CACHE_EMBEDS_DIR:-/work/embeds}"
CACHE_SO3_DIR="${BIOEMU_CACHE_SO3_DIR:-/work/so3}"

export TMPDIR="${TMPDIR:-/work/tmp}"
export MPLCONFIGDIR="${MPLCONFIGDIR:-/work/mpl}"
export JAX_PLATFORMS="${JAX_PLATFORMS:-cpu}"
export XLA_PYTHON_CLIENT_PREALLOCATE="${XLA_PYTHON_CLIENT_PREALLOCATE:-false}"
export TF_FORCE_GPU_ALLOW_GROWTH="${TF_FORCE_GPU_ALLOW_GROWTH:-true}"

mkdir -p \
  "${OUTPUT_DIR}" \
  "${CACHE_EMBEDS_DIR}" \
  "${CACHE_SO3_DIR}" \
  "${TMPDIR}" \
  "${MPLCONFIGDIR}"

if [[ -n "${BIOEMU_SAMPLE_CMD:-}" ]]; then
  read -r -a SAMPLE_CMD <<< "${BIOEMU_SAMPLE_CMD}"
elif command -v bioemu-sample-local >/dev/null 2>&1; then
  SAMPLE_CMD=(bioemu-sample-local)
else
  SAMPLE_CMD=(python -m bioemu.sample)
fi

EXTRA_ARGS=()
if [[ -n "${BIOEMU_EXTRA_ARGS:-}" ]]; then
  read -r -a EXTRA_ARGS <<< "${BIOEMU_EXTRA_ARGS}"
fi

"${SAMPLE_CMD[@]}" \
  "${SEQUENCE}" \
  "${NUM_SAMPLES}" \
  "${OUTPUT_DIR}" \
  --cache_embeds_dir "${CACHE_EMBEDS_DIR}" \
  --cache_so3_dir "${CACHE_SO3_DIR}" \
  --batch_size_100 "${BATCH_SIZE_100}" \
  "${EXTRA_ARGS[@]}"
