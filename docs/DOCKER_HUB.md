# Docker Hub Image

A ready-to-use BioEmu Docker image is available at:

[https://hub.docker.com/r/951753jalil/bioemu](https://hub.docker.com/r/951753jalil/bioemu)

## Pull And Run

```bash
docker pull 951753jalil/bioemu:latest
docker run --rm -it --gpus all -v "${PWD}:/work" -w /work 951753jalil/bioemu:latest bash
```

All repository scripts are intended to run inside the container:

```bash
bash test/run_all.sh
bash run_bioemu1.2_sampling.sh
bash run_bioemu1.2_sidechain.sh
```

## Short Description

```text
BioEmu Docker image for GPU sampling, ColabFold embeddings, HPacker side chains, and OpenMM relaxation.
```

## Longer Description

This image provides a BioEmu runtime for protein conformational ensemble
generation. It supports BioEmu backbone sampling from raw sequences, FASTA
files, or A3M files; cached ColabFold embeddings; GPU-enabled sampling; HPacker
side-chain reconstruction; and optional OpenMM minimization or MD
equilibration.

The repository scripts assume the container is already running and the project
folder is mounted as `/work`.

## Publish Or Update The Image

Build locally from this repository:

```bash
docker build -t 951753jalil/bioemu:latest .
```

Log in:

```bash
docker login
```

Push:

```bash
docker push 951753jalil/bioemu:latest
```

Optional version tag:

```bash
docker tag 951753jalil/bioemu:latest 951753jalil/bioemu:1.2
docker push 951753jalil/bioemu:1.2
```

Validate after pulling:

```bash
docker pull 951753jalil/bioemu:latest
docker run --rm -it --gpus all -v "${PWD}:/work" -w /work 951753jalil/bioemu:latest bash
bash test/run_all.sh
```
