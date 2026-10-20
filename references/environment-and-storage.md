# Environment and storage: user-provided cluster snapshot

Example environment inventory; verify installed modules and permissions on the live host before use. No sudo access is assumed.

## Environment policy

- **Strong preference**: project-local `uv` with explicit Python/package locks, `.venv`, and reproducible CUDA/torch/extension versions; `module load uv/0.9.9` is available.
- Do not assume the default Python (`python/3.13.7`) or CUDA (`cuda/12.9`) is correct for a given model. Match pinned interpreter/compiler/CUDA ABI and GPU architecture.
- Use no sudo, no global installs and no implicit conda fallback. If special packages need privileged setup, request an administrator action or an approved unprivileged alternative.

## User-supplied `module avail` (selected, full categories and versions)

| Family | Modules available |
|---|---|
| Python / package managers | `uv/0.9.9`, `python/3.10.12`, `python/3.11.13`, `python/3.12.3`, `python/3.12.11`, `python/3.13.7`, `python/3.13.7-nogil`, `miniconda3/25.5.1` |
| CUDA | `cuda/11.0`, `cuda/11.1.1`, `cuda/11.3`, `cuda/11.6`, `cuda/11.7.1`, `cuda/11.8`, `cuda/12.1`, `cuda/12.3`, `cuda/12.4.1`, `cuda/12.5`, `cuda/12.9` (default) |
| GPU / distributed | `nccl/2.23.4`, `nccl/2.25.1` (default), `nvhpc/25.5`, `nvhpc-nompi/25.5`, `nvhpc-byo-compiler/25.5`, `nvhpc-hpcx/25.5`, `nvhpc-hpcx-cuda12/25.5`, `nvhpc-hpcx-2.20-cuda12/25.5` |
| Compilers / build | `gcc/11.5.0`, `gcc/12.5.0`, `gcc/13.2.0`, `gcc/14.3.0` (default), `cmake/4.1.0`, `bazel/7.6.0`, `bazel/8.3.1` (default), `openmpi/4.1.8`, `hwloc/2.12.1`, `boost/1.89` |
| Media / tools | `ffmpeg/8.1`, `apptainer/1.4.1`, `nvidia-nsight-compute/2025.4.1.3`, `nvidia-nsight-systems/2026.3.1`, `graphviz/14.0.0`, `go/1.24.5` |
| Intel / libraries | `mkl/2025.2.0`, `intel/mkl/2025.2`, `intel/mpi/2021.16`, `intel/tbb/2022.2`, `intel/umf/0.11.0`, `intel/compiler/2025.2.0`, `intel/compiler-intel-llvm/2025.2.0`, `intel/compiler-rt/2025.2.0` |
| Other | `festival/2.5.0`, `julia/1.10.11`, `libxml2/2.14.5`, `mbrola/3.3`, `openjdk/17`, `openjdk/21` (default), `r/4.2.1`, `romeo/3.10.10`, `tcltk/8.4.19` |

Discover further module names with `module spider` or `module keyword ...`.

## Storage layout

| Path | Role | User-stated usable budget | Validation |
|---|---|---|---|
| Configured shared checkpoint root (see [SKILL.md](../SKILL.md)) | Common model/checkpoint storage | Within configured shared project budget | Existence, permissions and sharing conventions to check |
| Configured shared project root (see [SKILL.md](../SKILL.md)) | Shared project-area jobs/data | User-reported planning cap | Not verified as filesystem quota or currently free space |
| Configured `home_ids` path (see [SKILL.md](../SKILL.md)) | User home | User-reported planning cap | Approximate, not independently checked |
| Configured `home_infres` path (see [SKILL.md](../SKILL.md)) | Additional home/work area | User-reported planning cap | Approximate, not independently checked |

Never treat these figures as guaranteed free capacity. Project-specific output/log/tmp path conventions are not established. The shared checkpoints directory is not an implicit permission to overwrite/download weights there.

## Suggested verification (read-only)

```bash
module avail
module spider uv
module show uv/0.9.9
findmnt -T <configured-shared-project-root>
findmnt -T <configured-home-ids>
findmnt -T <configured-home-infres>
df -h <configured-shared-project-root> <configured-home-ids> <configured-home-infres>
df -i <configured-shared-project-root>
quota -s  # only where supported
```
