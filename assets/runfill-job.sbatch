#!/usr/bin/env bash
# CONDITIONAL TEMPLATE ONLY: do NOT submit before runfill preemption and recovery are verified.
# Use only for documented interruption-tolerant units and with per-batch approval.
# Usage :
# PROJECT_ROOT="xxx" bash runfill-job.sbatch --flag 1
# PROJECT_ROOT="xxx" sbatch runfill-job.sbatch --flag 1
#SBATCH --account=REPLACE_WITH_CONFIGURED_ACCOUNT
#SBATCH --qos=runfill
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
: "${PROJECT_ROOT:?Set PROJECT_ROOT to the approved project directory}"
cd "$PROJECT_ROOT"
module purge
module load cuda/12.9 uv/0.9.9
# Confirm true site behavior; do not assume automatic requeue, notifications or checkpoint signals.
# Ensure durable sample-level outputs, manifest, integrity checks and safe restart.
echo 'ERROR: runfill policy, recoverability and uv execution command require verification' >&2
exit 2
