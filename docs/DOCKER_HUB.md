# Docker Hub
https://github.com/Jalil-Mahdizadeh/BioEmu1.2.0

Ready-to-use image:

[https://hub.docker.com/r/951753jalil/bioemu](https://hub.docker.com/r/951753jalil/bioemu)

Pull and tag it with the name used in this repository:

```bash
docker pull 951753jalil/bioemu:latest
docker tag 951753jalil/bioemu:1.2.0 bioemu_full_slim:1.2.0
```

Start the container from the repository folder:

```bash
docker run --gpus all -it --rm --entrypoint /bin/bash -v /$PWD/:/workspace bioemu_full_slim:1.2.0
```

Inside the container:

```bash
cd /workspace
bash ./test/run_all.sh
```

The sampling scripts prepare ColabFold embeddings from the input sequence, then
run BioEmu sampling on CUDA. The image supports CUDA embeddings, but the scripts
default embedding generation to CPU because one-off ColabFold/JAX CUDA runs can
be slower due to XLA compilation. Set `JAX_PLATFORMS="cuda"` in the sampling
script to test or reuse the JAX GPU path.
