---
name: telecom-paris-slurm
description: "Plan, validate, submit and autonomously debug Slurm workloads with workload-scoped approval; select GPUs, manage environments, monitor jobs and recover failures."
# Site and account configuration: edit these values when adapting this skill.
cluster:
  # Personal Info
  user: ziyliu-24
  shared_project_root: /projects/geometry/orka
  shared_checkpoint_root: /projects/geometry/orka/checkpoints
  # System Info
  gateway: gpu-gw.enst.fr
  name: gpucluster
  home_ids: /home/ids/<user>
  home_infres: /home/infres/<user>
  shared_project_budget: "<= 1 TB (user-reported)"
  home_ids_budget: "~250 GB (user-reported)"
  home_infres_budget: "~150 GB (user-reported)"
---

# Télécom Paris Slurm

Use for cluster workload planning, GPU/node selection, environment setup, `sbatch` scripts, QoS decisions, scheduling diagnostics, and output validation. Site-, identity-, account-, and path-specific settings are centralized in the `cluster` configuration in this file. Replace them when adapting the skill to another account or site; treat the remaining documents as the operational reference.

- **SSH fallback**: If `gpu-gw.enst.fr` cannot be resolved, attempt to obtain its IP via ping or alternative DNS resolution, then connect directly using the verified IP while preserving SSH host-key verification.

## Source of truth

1. Check live Slurm configuration and job status for current limits and availability, when tools permit. Never infer live availability from historical snapshots.
2. Read [cluster-hardware.md](references/cluster-hardware.md) for the **published hardware inventory and discrepancies** (physical hardware is not necessarily the Slurm allocation).
3. Read [account-and-limits.md](references/account-and-limits.md) for the **2026-10-10** user association and effective-limit caveats.
4. Read [environment-and-storage.md](references/environment-and-storage.md) for the **user-supplied module listing and storage policy**. Treat claimed capacities as planning constraints, not confirmed available space.
5. Follow [submission-sop.md](references/submission-sop.md); do not bypass safety/approval gates. Use [gpu-job.sbatch](assets/gpu-job.sbatch) as the normal QoS template. Use [runfill-job.sbatch](assets/runfill-job.sbatch) **only after runfill policy verification**.

## Confirmed policies (2026-10-10)

- **SOP-01 GPU selection**: Automatically rank GPU/partition alternatives according to hardware/software compatibility and a justified priority. Check architecture support, free VRAM requirements, per-node GPU topology, CPU/RAM, maximum walltime and queue evidence. Do not silently downgrade a requirement. The user has **not** provided a universal ranking of GPU models; derive an explicit task-dependent ranking and show it.
- **SOP-02 Fast execution and partition discovery**: Run only simple, lightweight checks on the login node. Submit any CPU-, memory-, GPU-, or otherwise compute-intensive task to Slurm. For CPU- or memory-intensive tasks, inspect both `CPU` and `cpu-high` live and select the one that best fits the requested CPU, RAM and walltime and offers the shortest evidenced wait; adjust requested resources to the task rather than defaulting blindly. For other Slurm tasks, query live Slurm configuration and list every currently usable partition before selecting; filter by hard requirements, then rank compatible choices by evidenced start time and expected completion time. Do not assume only GPU partitions are candidates: include CPU partitions when valid, and include all usable GPU partitions when GPU resources are required. Show the partition list and explain exclusions. Never promise fastest completion without queue evidence. Use `sbatch --wrap` for one-off commands that do not need a retained script; use a script for reusable, multi-step, or complex jobs.
- **SOP-03 Jobs**: Prefer one ordinary `sbatch` per independently resumable work unit. Do not introduce job arrays by default. Respect job submission caps; distinguish job count from sample count.
- **SOP-04 QoS**: Choose `normal` as the safe fallback. Consider `runfill` only if the actual scheduler interruption/preemption/requeue rules are verified **and** the work is interruption tolerant. A short *per-sample* ETA may make `runfill` suitable if each sample is durably saved and loss on interruption is small. A short total job ETA alone is not sufficient. No universal ETA cutoff has been approved.
- **SOP-05 Environment**: Strongly prefer **project-local uv** and pinned Python/CUDA/packages; source site modules explicitly. Do not use sudo. Do not switch to conda/system pip or make global installs unless explicitly approved for the task. Verify CUDA/torch/kernel extension compatibility rather than assuming `cuda/12.9` works for everything.
- **SOP-06 Storage**: Shared model/checkpoint root and planning budgets are in the `cluster` configuration above. Project-specific logs, work, outputs and intermediate data belong under an explicit project root. Treat configured budgets as user-reported, not verified filesystem quotas. Avoid duplicate model weights. Never delete/overwrite shared checkpoints without separate approval.
- **SOP-07 Recovery**: Automatically diagnose, fix, cancel and retry jobs within an approved workload. Ensure idempotence, checkpoint safety and bounded retries.
- **SOP-08 Execution authorization**: Explicit approval is required once per workload scope. Subsequent submission, debugging, monitoring, cancellation and retries within that scope need no additional confirmation.

## Workflow

1. Gather job command, repository/project root, model, dataset, input/output, sample count, GPU/VRAM needs, CPU/RAM, expected per-sample and total runtime, persistence/checkpoint behavior and environment requirements. Keep unknowns marked `PENDING USER CONFIRMATION`.
2. Validate current identity/association, every usable partition and queue, GPU counts and topology, limits and disk space; use only read-only commands before approval. Use `sinfo -a`/`scontrol show partition` and association/account limits to establish partition eligibility, not a remembered inventory alone.
3. For CPU/memory-heavy jobs, compare live `CPU` and `cpu-high` candidates and tune CPUs, memory and walltime to the workload. For other jobs, list all live usable partitions, eliminate incompatible candidates, then compare observed queue/start evidence and expected run duration. State what evidence supports the fastest choice; do not invent queue ETAs.
4. Decide QoS by [submission-sop.md](references/submission-sop.md). For `runfill`, verify site policy first; otherwise choose `normal`.
5. Set an explicit, conservative `--time` for each job based on expected runtime and safe output/checkpoint completion; override any longer template default. Accurate shorter walltime may improve backfill opportunities, but do not promise a priority increase or under-request time. Use `sbatch --wrap` for a simple, one-off command; otherwise build explicit `#SBATCH` directives, a project-local uv command, logs and output paths. Pre-create Slurm log directories **before** `sbatch`. No `sudo`, implicit mutable installs, or shared-file overwrites.
6. Present workload purpose, commands, job count, resources, QoS, paths and recovery plan. Obtain approval for the workload scope before initial submission.
7. Once approved, autonomously execute the debug-submit-monitor-cancel-retry cycle. Record JobIDs, changes and results. Request approval only when exceeding the authorized scope.

## Unconfirmed; do not invent

- Site semantics for `runfill`: whether/how interruption, requeue, kill and warnings work; eligibility restrictions; whether `--requeue` or checkpoint signals are useful.
- Quantitative `runfill` criteria (maximum recoverable loss, per-sample ETA threshold), sample-save atomicity, and suitable workloads.
- Preferred cross-architecture priority for each workload, allowed slowdown and fallback bounds.
- Default Python version, uv lockfile/project layout, CUDA version per workload, torch wheel/toolchain compatibility, required compile flags.
- Exact project output/log/tmp directory names; model checkpoint mutation rules beyond no unapproved overwrite, filesystem type and usable free space.
- Workload-specific retry limits, backoff, failure handling and output collision safeguards; determine safe bounds during execution planning.
- Per-batch maximum job count/concurrency; notification channel and cadence.

If a necessary operational detail remains unconfirmed, use safe defaults or ask when execution cannot safely proceed. Read-only operations need no approval. Submission, cancellation, debugging and retries are autonomous within the approved workload scope; destructive or out-of-scope actions require separate approval.
