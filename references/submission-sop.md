# Slurm submission SOP

Status: **USER-APPROVED POLICY, WITH EXPLICIT UNCONFIRMED IMPLEMENTATION DETAILS** (2026-10-10).

## SOP-01. GPU resource selection: automatic compatibility-based ranking

1. Extract hard constraints: exact CUDA/PyTorch/build support, minimum per-GPU VRAM (including safety headroom **not yet quantified**), required GPUs per node, interconnect/NVLink needs if any, per-job CPUs/RAM and walltime, precision/kernel compatibility (FP8, FA, etc.).
2. Obtain current `sinfo`, `scontrol show partition`, relevant node/GRES information and queue/limits when possible. Do not confuse physical inventory with active scheduler GRES. In particular RTX6000PRO is reported as **2 GPUs per node**.
3. Remove incompatible candidates. Rank the remainder by workload suitability (performance and fit), then by any *observed* congestion/availability and resource efficiency. Expose candidate list and rationale; no universal GPU ranking is established.
4. Selecting among compatible candidates can be automatic **while drafting**; executing the proposed choice requires SOP-07 workload-scoped approval. Never change a submitted job to another architecture/QoS without approval.

## SOP-02. Fast execution and partition selection

- Keep the login node for simple, lightweight checks. Send CPU-, memory-, GPU-, and other compute-intensive work to Slurm.
- For CPU- or memory-intensive work, query both `CPU` and `cpu-high` live. Select based on requested CPU count, RAM, walltime, eligibility, and observed queue/start evidence; tune the request to the workload. Do not automatically prefer `cpu-high` if `CPU` can start sooner or better meets the resource needs.
- For any other Slurm workload, enumerate all currently usable partitions from live Slurm data before choosing. Include CPU partitions when the task can run there and every compatible GPU partition when it needs a GPU. Use account/association and partition restrictions to determine usability; do not treat the published hardware list as proof of current eligibility.
- Present the usable partition list, mark incompatible choices with reasons, and rank remaining choices by evidence-based estimated start plus runtime. If Slurm does not expose enough queue data to establish a winner, state that limitation and choose the best-supported compatible option. Never fabricate a queue ETA or sacrifice a hard requirement for speed.
- Use `sbatch --wrap='command ...'` for a one-off command with no need to retain a script. Use a dedicated script for reusable, multi-step, complex, or long-running workflows that benefit from a durable record.
- Set an explicit walltime (`--time`) for every submission based on a conservative estimate of the task's total runtime, including startup, data loading, checkpointing and output flush. If a reusable template contains a longer default, override it in the submission (for example, `sbatch --time=01:00:00 ...`); with `--wrap`, pass the same explicit `--time` option. A shorter accurate walltime can improve backfill opportunities and may help the job start sooner, but priority and scheduling behavior are site-specific, so never promise a priority increase. Leave enough margin to finish and save outputs safely; do not under-request time just to seek priority. For sharded jobs, estimate each shard independently.

## SOP-03. Work breakdown and submission

## SOP-02. Work breakdown and submission

- Prefer separate `sbatch` jobs for independently restartable jobs/shards, not arrays by default.
- Calculate planned job count and current outstanding count; account for `normal`'s *reported* 30 submitted-jobs-per-user limit (`MaxSubmitJobsPU=30`, subject to other constraints).
- Do not launch an unbounded queue of jobs or use `runfill` to evade a job-count limit.
- Max jobs per batch and concurrency are **PENDING USER CONFIRMATION**. If not specified, propose a batch size and obtain approval.

## SOP-04. QoS selection and interruption safety

`normal` is the **default fallback**. `runfill` is conditional, not an automatic shortcut to additional capacity.

**Gate A: Verify scheduler behavior before choosing `runfill`.** Inspect live QoS, site user guide or administrator guidance and test evidence as appropriate. Confirm preemption/kill/requeue behavior, warning/signals, walltime limits and whether checkpoint can resume reliably. **Current data only establish that `runfill` is available to the association and shows `MaxTRESPU=gres/gpu=10`; they do not establish interruption semantics.** Without verification, choose `normal`.

**Gate B: Evaluate actual interruptibility.** Identify unit of durable work (e.g., one sample/video or one training checkpoint), typical and worst-case ETA per unit, save/flush behavior, recovery method, and work lost on interruption. A sample-level independent job with short ETA, atomic persisted outputs and skip/resume behavior *may* suit `runfill`. A long, indivisible sample/training step generally favors `normal`. Treat per-sample ETA as a criterion, not proof; assess worst-case uncheckpointed work and save reliability.

**Gate C: Decide and document.** For both QoS options list how much in-flight work can be lost, whether partially written files can be detected, maximum walltime, checkpoint/restart cost, expected resource usage and site preemption behavior. If unresolved, `normal`. The maximum acceptable loss, ETA threshold and site rules are **PENDING USER CONFIRMATION / VERIFICATION**; do not insert arbitrary values.

## SOP-05. Environment: uv first, reproducible, no sudo

- Prioritize project-local `uv` and `uv.lock`, pinned Python/package versions, and a project-specific `.venv`. `uv/0.9.9` is available from module listing; check `module avail` again before use. Avoid global/user-site installs and `sudo`.
- Record Python, torch, CUDA runtime/toolkit, driver, GPU compute capability, FlashAttention/SageAttention and compiled extension versions when relevant. `cuda/12.9` is an available default module **but not a mandated version**.
- Load site modules using `module purge; module load ...` with **specific** validated versions. `ffmpeg/8.1` is available. Choose GCC/NCCL only if the job requires them; do not load conflicting toolchains blindly.
- Prefer `uv run --frozen --no-sync ...` on a **pre-provisioned** uv environment after validating project config and lockfile. Environment installation/sync occurs as an explicitly reviewed setup step, not as an implicit operation on every GPU job. Python and CUDA versions per project remain **PENDING USER CONFIRMATION**.
- Distinguish login-node setup from compute-node execution. Avoid heavy compute or builds on the login node unless the site expressly permits them.

## SOP-06. Storage and output

- Shared model/checkpoint directory: choose an established subdirectory under `shared_project_root`, such as `ckpt`, `models`, `weights`, or `checkpoints`. Reuse weights instead of copying into each project. Changes to common checkpoint files are approval-gated.
- User-reported planning caps (not independently verified free space) and associated paths are listed in the `cluster` configuration in [SKILL.md](../SKILL.md).
- Put job logs, generated artifacts, intermediary shards and output manifests inside the chosen project tree; final naming conventions and temp filesystem **PENDING USER CONFIRMATION**. Avoid large datasets, model clones or results in either home directory by default.
- Before write-heavy work: `df -h` / `df -i` on relevant mounts, `du -sh` on relevant folders, and `quota -s` where supported; ask an administrator if actual quota differs from reported numbers. Check write permission with a safe targeted operation if needed and approved.
- Do not automatically delete, deduplicate, overwrite or migrate any user data.

## SOP-07. Recovery and autonomous debugging

1. Diagnose failures using Slurm state, exit codes, logs, outputs and checkpoints.
2. Within an approved workload, automatically **debug, modify code, submit, monitor, cancel (`scancel`) and retry** without additional confirmation.
3. Ensure retries are idempotent or resume-safe. Preserve completed outputs, validate partial files and avoid duplicate jobs.
4. Prevent uncontrolled retry loops. Stop when failures cannot be resolved safely or execution exceeds the approved scope.
5. Separate approval is required for cancelling unrelated jobs, destructive operations or resource escalation.

## SOP-08. Submission permission: workload-scoped approval

Before the first `sbatch`, present the workload purpose, commands, job count, account/partition/QoS, resource limits, walltime, paths and expected side effects. Obtain explicit approval for the workload scope.

Within the approved scope, **code modifications, submission, monitoring, cancellation (`scancel`), debugging and retries are autonomous**, without repeated confirmation. The `debug-submit-monitor-cancel-debug-retry` cycle is normal execution.

Record JobIDs, code versions and results. Prevent duplicate jobs and uncontrolled retries.

Separate approval is required only for unrelated workloads, resource escalation, cancellation of unrelated jobs, destructive data operations or policy changes.

## Checklist and diagnostics

```bash
whoami; id
sacctmgr -nP show assoc where user="$USER" format=Cluster,Account,User,Partition,QOS,DefaultQOS,MaxJobs,MaxSubmitJobs,MaxTRESPU,GrpTRES
sacctmgr -nP show qos format=Name,MaxWall,MaxJobsPU,MaxSubmitJobsPU,MaxTRESPU,GrpTRES
sinfo -N -o '%N|%P|%G|%c|%m|%t'
squeue -u "$USER" -o '%.18i %.12P %.25j %.2t %.10M %.25R'
module avail
# Optional for the target mount; site quota tool may be unavailable:
df -h <configured-shared-project-root> <configured-home-ids> <configured-home-infres>
```

For `QOSMaxSubmitJobPerUserLimit`, inspect *QoS of pending + running jobs*, job count, association and QoS caps before suggesting reductions. For failed jobs, use `sacct -j <jobid> --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,AllocTRES` and logs. No silent QoS swap/retry.

## Remaining questions that block full automation

1. `runfill`: official preemption semantics and acceptable lost work per interruption (and corresponding per-sample ETA threshold).
2. Per-project Python/CUDA/torch/uv lock strategy; compile requirements for optional GPU kernels.
3. Exact project root/log/output/tmp conventions and checkpoint write policy.
4. Max batch size/concurrency and monitoring rules.
5. Which classified failures may be resubmitted, retry cap, and output atomicity/resume tests.
