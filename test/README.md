# BioEmu Smoke Tests

Run these tests inside a BioEmu container with this repository mounted as
`/work`.

```bash
bash test/run_all.sh
```

The tests do two things:

- `run_5_sampling_gpu.sh` creates five BioEmu samples and requires GPU access by
  default.
- `run_one_sidechain_cpu.sh` reconstructs side chains for one sampled frame and
  uses CPU by default.

Outputs are written under `test/output/`, which is ignored by git.

Useful overrides:

```bash
BIOEMU_TEST_REQUIRE_GPU=0 bash test/run_5_sampling_gpu.sh
BIOEMU_TEST_NUM_SAMPLES=10 bash test/run_5_sampling_gpu.sh
BIOEMU_TEST_SIDECHAIN_USE_GPU=1 bash test/run_one_sidechain_cpu.sh
BIOEMU_TEST_MD_EQUIL=1 bash test/run_one_sidechain_cpu.sh
```

The sampling test uses `test/data/test_sequence.a3m`, so it does not need a
remote MSA search for the smoke-test sequence.
