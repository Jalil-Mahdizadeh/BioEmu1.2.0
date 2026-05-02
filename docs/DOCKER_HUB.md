# Docker Hub

Ready-to-use image:

[https://hub.docker.com/r/951753jalil/bioemu](https://hub.docker.com/r/951753jalil/bioemu)

Pull and tag it with the name used in this repository:

```bash
docker pull 951753jalil/bioemu:latest
docker tag 951753jalil/bioemu:latest bioemu_full_slim:latest
```

Start the container from the repository folder:

```bash
docker run --gpus all -it --rm --entrypoint /bin/bash -v /$PWD/:/workspace bioemu_full_slim:latest
```

Inside the container:

```bash
cd /workspace
bash ./test/run_all.sh
```

## Docker Hub Description

Short description:

```text
BioEmu Docker image for GPU sampling, ColabFold embeddings, HPacker side chains, and OpenMM relaxation.
```

Long description:

```text
BioEmu Docker image for protein conformational ensemble generation. Supports BioEmu backbone sampling from raw sequences, FASTA files, or A3M files; cached ColabFold embeddings; GPU sampling; HPacker side-chain reconstruction; and optional OpenMM minimization or MD equilibration.
```

## Push

```bash
docker login
docker tag bioemu_full_slim:latest 951753jalil/bioemu:latest
docker push 951753jalil/bioemu:latest
```
