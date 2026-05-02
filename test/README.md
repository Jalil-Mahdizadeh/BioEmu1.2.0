# Smoke Test

Run inside the container from `/workspace`:

```bash
bash ./test/run_all.sh
```

The test scripts have editable parameters at the top:

- `test/run_5_sampling_gpu.sh`: five BioEmu samples, GPU required for sampling.
- `test/run_one_sidechain_cpu.sh`: one side-chain reconstruction, CPU by default.

Outputs go to `test/output/`.

The sampling scripts keep ColabFold/JAX embeddings on CPU for compatibility, but
BioEmu sampling itself uses CUDA after embeddings are ready or cached.
