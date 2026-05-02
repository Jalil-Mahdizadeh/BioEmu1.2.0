# BioEmu Docker Runner

This repository provides simple scripts for running BioEmu sampling and
side-chain reconstruction inside a BioEmu Docker container.

A ready-to-use image is available on Docker Hub:

[https://hub.docker.com/r/951753jalil/bioemu](https://hub.docker.com/r/951753jalil/bioemu)

You can also build your own image from the included `Dockerfile`.

## Features

- BioEmu backbone sampling from a raw sequence, FASTA file, or A3M file.
- GPU sampling when the container is started with GPU access.
- Persistent output, embedding cache, and SO3 cache folders under `/work`.
- HPacker side-chain reconstruction.
- Optional OpenMM local minimization or short MD equilibration.
- Smoke tests for five samples and one side-chain reconstruction.

## Start A Container

Use the published image:

```bash
docker pull 951753jalil/bioemu:latest
docker run --rm -it --gpus all -v "${PWD}:/work" -w /work 951753jalil/bioemu:latest bash
```

Or build an image yourself:

```bash
docker build -t my-bioemu .
docker run --rm -it --gpus all -v "${PWD}:/work" -w /work my-bioemu bash
```

All commands below are meant to be run inside the container.

## Quick Test

Run five sampling steps on GPU by default, then reconstruct side chains for one
frame on CPU by default:

```bash
bash test/run_all.sh
```

The test output is written to `test/output/`, which is ignored by git.

## Sampling

Run the default NusA SKK-CTD sampling job:

```bash
bash ./run_bioemu1.2_sampling.sh
```

Run a short custom job:

```bash
BIOEMU_SEQUENCE=/work/test/data/test_sequence.a3m \
BIOEMU_NUM_SAMPLES=5 \
BIOEMU_OUTPUT_DIR=/work/out/example-5 \
BIOEMU_BATCH_SIZE_100=5 \
BIOEMU_EXTRA_ARGS="--filter_samples False --base_seed 17" \
bash ./run_bioemu1.2_sampling.sh
```

### Sampling Parameters

| Variable | Default | Description |
| --- | --- | --- |
| `BIOEMU_SEQUENCE` | NusA SKK-CTD sequence | Raw amino-acid sequence, FASTA path, or A3M path. |
| `BIOEMU_NUM_SAMPLES` | `10000` | Total number of samples to produce. Existing samples in the output directory are reused. |
| `BIOEMU_OUTPUT_DIR` | `/work/out/NusA-SKK-CTD-10k` | Output directory for `batch_*.npz`, `topology.pdb`, and `samples.xtc`. |
| `BIOEMU_BATCH_SIZE_100` | `250` | Batch size normalized to a 100-residue sequence. Lower this if GPU memory is tight. |
| `BIOEMU_CACHE_EMBEDS_DIR` | `/work/embeds` | ColabFold embedding cache. |
| `BIOEMU_CACHE_SO3_DIR` | `/work/so3` | SO3 precomputation cache. |
| `BIOEMU_SAMPLE_CMD` | Auto-detected | Sampling command. Uses `bioemu-sample-local` when available, otherwise `python -m bioemu.sample`. |
| `BIOEMU_EXTRA_ARGS` | Empty | Extra arguments passed to BioEmu sampling. |

Useful `BIOEMU_EXTRA_ARGS` values:

| Argument | Description |
| --- | --- |
| `--model_name bioemu-v1.2` | Select a named BioEmu model when not using the image wrapper command. |
| `--ckpt_path PATH` | Use a custom checkpoint. |
| `--model_config_path PATH` | Config path required with a custom checkpoint. |
| `--denoiser_type dpm` | Use the DPM denoiser. |
| `--denoiser_type heun` | Use the Heun denoiser. |
| `--msa_host_url URL` | Use a custom ColabFold MSA server. Ignored for A3M input. |
| `--filter_samples False` | Disable physical sample filtering for quick tests. |
| `--base_seed 17` | Set a reproducible base seed. |

Sampling outputs:

- `sequence.fasta`
- `batch_*.npz`
- `topology.pdb`
- `samples.xtc`

## Side-Chain Reconstruction

Run side-chain reconstruction for the default selected NusA frames:

```bash
bash ./run_bioemu1.2_sidechain.sh
```

Run side-chain reconstruction only, without OpenMM minimization:

```bash
BIOEMU_MD_EQUIL=0 \
BIOEMU_PDB_PATH=/work/out/example-5/topology.pdb \
BIOEMU_XTC_PATH=/work/out/example-5/samples.xtc \
BIOEMU_SIDECHAIN_OUTPATH=/work/out/example-5/sidechain \
BIOEMU_SIDECHAIN_PREFIX=example \
bash ./run_bioemu1.2_sidechain.sh
```

### Side-Chain Parameters

| Variable | Default | Description |
| --- | --- | --- |
| `BIOEMU_PDB_PATH` | `/work/out/NusA-full-10k/selected-frames/topology.pdb` | Backbone topology PDB. |
| `BIOEMU_XTC_PATH` | `/work/out/NusA-full-10k/selected-frames/selected_frames.xtc` | Backbone trajectory XTC. |
| `BIOEMU_SIDECHAIN_OUTPATH` | `/work/out/NusA-full-10k/selected-frames/sidechain` | Output directory. |
| `BIOEMU_SIDECHAIN_PREFIX` | `NusA` | Prefix for output files. |
| `BIOEMU_MD_EQUIL` | `1` | `1` enables OpenMM minimization/equilibration; `0` reconstructs side chains only. |
| `BIOEMU_MD_PROTOCOL` | `local_minimization` | `local_minimization` or `md_equil`. |
| `BIOEMU_SIMTIME_NS` | `0` | Optional unconstrained MD simulation time in ns. |
| `BIOEMU_SIDECHAIN_CMD` | Auto-detected | Side-chain command. Uses `bioemu-sidechain-relax` when available, otherwise `python -m bioemu.sidechain_relax`. |
| `BIOEMU_SIDECHAIN_EXTRA_ARGS` | Empty | Extra arguments passed to the side-chain command. |

Side-chain outputs:

- `<prefix>_sidechain_rec.pdb`
- `<prefix>_sidechain_rec.xtc`
- `<prefix>_md_equil.pdb` when MD equilibration is enabled
- `<prefix>_md_equil.xtc` when MD equilibration is enabled

## Build Your Own Image

The Dockerfile installs BioEmu from public sources:

```bash
docker build -t my-bioemu .
```

Build arguments:

| Argument | Default | Description |
| --- | --- | --- |
| `PYTHON_VERSION` | `3.10` | Python version installed into the image. |
| `BIOEMU_MODEL` | `bioemu-v1.2` | Model to pre-download and use by default. |
| `PRELOAD_BIOEMU_MODEL` | `1` | Download BioEmu model files at build time. |
| `PRELOAD_COLABFOLD` | `1` | Install ColabFold and AlphaFold2 params at build time. |
| `PREINSTALL_HPACKER` | `1` | Install HPacker side-chain dependencies at build time. |

## Repository Layout

```text
.
├── Dockerfile
├── README.md
├── requirements.txt
├── run_bioemu1.2_sampling.sh
├── run_bioemu1.2_sidechain.sh
├── docs/
│   ├── BUILD_IMAGE.md
│   └── DOCKER_HUB.md
└── test/
    ├── README.md
    ├── data/test_sequence.a3m
    ├── run_5_sampling_gpu.sh
    ├── run_one_sidechain_cpu.sh
    └── run_all.sh
```

Ignored runtime folders:

- `out/`
- `embeds/`
- `so3/`
- `tmp/`
- `mpl/`
- `test/output/`
