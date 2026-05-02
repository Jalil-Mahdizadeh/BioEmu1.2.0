#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# EDIT THIS SECTION
# ============================================================

WORKSPACE="/workspace"

# Protein sequence, FASTA file, or A3M file.
SEQUENCE="TGVVKKVNRDNISLDLGNNAEAVILREDMLPRENFRPGDRVRGVLYSVRPEARGAQLFVTRSKPEMLIELFRIEVPEIGEEVIEIKAAARDPGSRAKIAVKTNDKRIDPVGACVGMRGARVQAVSTELGGERIDIVLWDDNPAQFVINAMAPADVASIVVDEDKHTMDIAVEAGNLAQAIGRNGQNVRLASQLSGWELNVMTVDDLQAKHQAEAHAAIDTFTKYLDIDEDFATVLVEEGFSTLEELAYVPMKELLEIEGLDEPTVEALRERAKNALATIAQAQEESLGDNKPADDLLNLEGVDRDLAFKLAARGVCTLEDLAEQGIDDLADIEGLTDEKAGALIMAARNICWFGDEA"

# Sampling settings.
NUM_SAMPLES=10000
BATCH_SIZE_100=250
OUTPUT_DIR="${WORKSPACE}/out/example-sampling-10k"

# Cache folders.
CACHE_EMBEDS_DIR="${WORKSPACE}/embeds"
CACHE_SO3_DIR="${WORKSPACE}/so3"

# BioEmu options.
DENOISER_TYPE="dpm"
FILTER_SAMPLES="True"
BASE_SEED=""          # Empty means random seed.
MSA_HOST_URL=""       # Empty means BioEmu/ColabFold default.

# ColabFold/JAX embedding generation.
# Use "cpu" on this Blackwell GPU because ColabFold/JAX crashes on GPU with:
#   Unsupported conversion from bf16 to f16
# BioEmu sampling still uses the GPU after embeddings are ready or cached.
JAX_PLATFORMS="cpu"

# ============================================================
# DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU ARE CHANGING
# ============================================================

export TMPDIR="${WORKSPACE}/tmp"
export MPLCONFIGDIR="${WORKSPACE}/mpl"
export JAX_PLATFORMS
export XLA_PYTHON_CLIENT_PREALLOCATE="false"
export TF_FORCE_GPU_ALLOW_GROWTH="true"

mkdir -p \
  "${OUTPUT_DIR}" \
  "${CACHE_EMBEDS_DIR}" \
  "${CACHE_SO3_DIR}" \
  "${TMPDIR}" \
  "${MPLCONFIGDIR}"

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
