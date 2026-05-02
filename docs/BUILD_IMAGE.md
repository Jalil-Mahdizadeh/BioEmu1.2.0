# Build The Image

Build your own BioEmu image from this repository:

```bash
docker build -t bioemu_full_slim:latest .
```

Then start it from the repository folder:

```bash
docker run --gpus all -it --rm --entrypoint /bin/bash -v /$PWD/:/workspace bioemu_full_slim:latest
```

Inside the container:

```bash
cd /workspace
bash ./test/run_all.sh
```

Optional build arguments:

```bash
docker build \
  --build-arg BIOEMU_MODEL=bioemu-v1.2 \
  --build-arg PRELOAD_COLABFOLD=1 \
  --build-arg PREINSTALL_HPACKER=1 \
  --build-arg COLABFOLD_JAX_VERSION=0.5.3 \
  --build-arg COLABFOLD_HAIKU_VERSION=0.0.16 \
  -t bioemu_full_slim:latest \
  .
```

The ColabFold JAX pins allow embedding generation to run on CUDA while remaining
compatible with ColabFold 1.5.4. The runner scripts still default embedding
generation to CPU because one-off CUDA embedding runs can be slower due to XLA
compilation; set `JAX_PLATFORMS="cuda"` in the sampling script when you want to
test or reuse the JAX GPU path.
