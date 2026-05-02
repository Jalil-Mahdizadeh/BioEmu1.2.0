# Build A BioEmu Image

The included `Dockerfile` builds a BioEmu runtime from public packages. It does
not require access to any private or prebuilt image.

## Standard Build

```bash
docker build -t my-bioemu .
```

Run it with this repository mounted as `/work`:

```bash
docker run --rm -it --gpus all -v "${PWD}:/work" -w /work my-bioemu bash
```

Then run the scripts inside the container:

```bash
bash test/run_all.sh
```

## Build Arguments

| Argument | Default | Description |
| --- | --- | --- |
| `PYTHON_VERSION` | `3.10` | Python version installed into the image. |
| `BIOEMU_MODEL` | `bioemu-v1.2` | Model downloaded and used by default. |
| `PRELOAD_BIOEMU_MODEL` | `1` | Download BioEmu checkpoint/config at build time. |
| `PRELOAD_COLABFOLD` | `1` | Install ColabFold and AlphaFold2 parameters at build time. |
| `PREINSTALL_HPACKER` | `1` | Install HPacker side-chain dependencies at build time. |

Example:

```bash
docker build \
  --build-arg BIOEMU_MODEL=bioemu-v1.2 \
  --build-arg PRELOAD_COLABFOLD=1 \
  --build-arg PREINSTALL_HPACKER=1 \
  -t my-bioemu \
  .
```

For a smaller image that downloads more on first use:

```bash
docker build \
  --build-arg PRELOAD_COLABFOLD=0 \
  --build-arg PREINSTALL_HPACKER=0 \
  -t my-bioemu \
  .
```

## Requirements File

`requirements.txt` is used during the Docker build and installs:

```text
bioemu[cuda,md]==1.3.1
```

The `cuda` extra provides GPU-capable BioEmu dependencies. The `md` extra
provides OpenMM support for relaxation.
