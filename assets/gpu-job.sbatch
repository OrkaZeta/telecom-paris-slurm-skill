#!/usr/bin/env bash
# TEMPLATE ONLY — not approved for submission as-is.
# Fill directives and verify all resource/environment values before per-batch approval.
# Usage :
# PROJECT_ROOT="xxx" bash gpu-job.sbatch --flag 1
# PROJECT_ROOT="xxx" sbatch gpu-job.sbatch --flag 1
#SBATCH --account=REPLACE_WITH_CONFIGURED_ACCOUNT
#SBATCH --qos=normal
#SBATCH --partition=H100
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=32G
#SBATCH --time=1-00:00:00
#SBATCH --job-name=REPLACE_JOB_NAME
#SBATCH --output=REPLACE_LOG_DIR/%x-%j.out
#SBATCH --error=REPLACE_LOG_DIR/%x-%j.err

set -euo pipefail
# STOP: replace the placeholder command and script paths before submission.
: "${PROJECT_ROOT:?Set PROJECT_ROOT to the approved project directory}"
cd "$PROJECT_ROOT"
module purge
module load cuda/12.9 uv/0.9.9
# Optional, if used: module load ffmpeg/8.1
# CUDA 12.9 here is an EXAMPLE: verify driver / torch / kernels / project pin.
command -v uv
uv --version
nvidia-smi
# Setup/sync uv.lock & .venv as an explicitly approved, separate preparatory step.
# Running with --frozen --no-sync assumes a populated project-local .venv.
# Replace with e.g.: srun uv run --frozen --no-sync python -m YOUR_PACKAGE ...
echo 'ERROR: Replace this template with an approved uv command before submission' >&2
exit 2
