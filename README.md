# BioEmu Docker Runner

Simple BioEmu runner scripts for use inside a Docker container.

Ready-to-use image:

[https://hub.docker.com/r/951753jalil/bioemu](https://hub.docker.com/r/951753jalil/bioemu)

## 1. Get The Image

Use the Docker Hub image:

```bash
docker pull 951753jalil/bioemu:latest
docker tag 951753jalil/bioemu:latest bioemu_full_slim:latest
```

Or build it yourself:

```bash
docker build -t bioemu_full_slim:latest .
```

## 2. Start The Container

From this folder on the host machine:

```bash
docker run --gpus all -it --rm --entrypoint /bin/bash -v /$PWD/:/workspace bioemu_full_slim:latest
```

Inside the container:

```bash
cd ../..workspace
```

## 3. Edit The Script You Want

Open one of these files and edit the values in the `EDIT THIS SECTION` block:

- `run_bioemu1.2_sampling.sh`
- `run_bioemu1.2_sidechain.sh`
- `test/run_5_sampling_gpu.sh`
- `test/run_one_sidechain_cpu.sh`

The sampling script is set to five samples by default. Change `SEQUENCE`,
`NUM_SAMPLES`, `BATCH_SIZE_100`, and `OUTPUT_DIR` in the script as needed.

## 4. Run

Sampling:

```bash
bash ./run_bioemu1.2_sampling.sh
```

The sampling script first prepares embeddings from `SEQUENCE` into
`/workspace/embeds`, then runs BioEmu sampling on CUDA. Embedding generation is
CPU by default because one-off ColabFold/JAX GPU embedding jobs can be slower
than CPU due to first-run XLA compilation. To test GPU embeddings, set
`JAX_PLATFORMS="cuda"` in the script. Repeated CUDA embedding runs can reuse
`/workspace/jax_compile_cache`.

Side-chain reconstruction:

```bash
bash ./run_bioemu1.2_sidechain.sh
```

Short test:

```bash
bash ./test/run_all.sh
```

The short test runs five GPU samples and one CPU side-chain reconstruction.

## Output Folders

Generated files are ignored by git:

- `out/`
- `embeds/`
- `so3/`
- `jax_compile_cache/`
- `tmp/`
- `mpl/`
- `test/output/`

## Files

- `run_bioemu1.2_sampling.sh`: main sampling script.
- `run_bioemu1.2_sidechain.sh`: main side-chain script.
- `test/`: short image validation scripts.
- `Dockerfile`: build your own image.
- `requirements.txt`: Python package used by the Dockerfile.
