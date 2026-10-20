# Slurm association, QoS, and limit snapshot

## Slurm Access and Limits

### Confirmed identity and account (2026-10-10)

- User, groups, cluster and account are configured at the top of [SKILL.md](../SKILL.md). Replace this site-specific association snapshot with live output for the configured identity.
- Association has no partition restriction in the displayed record; QoS allowed by association: `normal`, `runfill`. `DefaultQOS` field was empty; **do not assume** which QoS is selected automatically.
- Published `AllowGroups` on A100, V100, P100, A30, A40, 3090, L40S, H100, RTX6000PRO, audible, CPU, and cpu-high all include `images`, and `AllowAccounts=ALL`. This establishes **group/account eligibility**, not a guarantee that every submission succeeds.
- The default partition shown in Slurm is `P100` (`Default=YES`). Prefer `--partition` explicitly for reproducible resource selection.

### QoS limits

| QoS | Available for this association? | Max submitted jobs per user | Max running jobs per user | GPU limit (`MaxTRESPU`) | Other |
|---|---|---:|---:|---:|---|
| `normal` | Yes | 30 | Not shown | 8 | No `MaxWall` limit in QoS output; partition max time still applies |
| `runfill` | Yes | Not shown | Not shown | 10 | No `MaxWall` limit in QoS output; partition max time still applies |

Other QoS entries (`qos-student`, `qos_h100_0`, `qos-mm`, etc.) were visible in the global QoS listing but **not assigned** to this user in their association. A blank limit means *not specified in that displayed QoS field*, **not unlimited effective access**. Association, account, resource, and site-wide restrictions may still apply. `normal`'s `MaxSubmitJobsPU=30` can explain `QOSMaxSubmitJobPerUserLimit` when the active QoS is `normal`; verify job QoS before attributing an error conclusively.

### Fair-share snapshot

`sshare` showed: `Account=images`, `RawShares=1`, `NormShares=0.001481`, `RawUsage=32467149`, `NormUsage=0.005305`, `EffectvUsage=0.005305`, `FairShare=0.075691`, `LevelFS=0.279243`. These values change over time and are relevant to scheduling priority, not permission to access a partition.

### Read-only diagnostics

```bash
# Association, default account/QoS, and all applicable account/association caps
sacctmgr -nP show assoc where user="$USER" format=Cluster,Account,User,Partition,QOS,DefaultQOS,MaxJobs,MaxSubmitJobs,MaxTRESPU,GrpTRES
sacctmgr -nP show user "$USER" withassoc

# Live per-node configured GPUs, partition, memory and status
sinfo -N -o '%N|%P|%G|%c|%m|%t'
scontrol show node node22
scontrol show node node52
scontrol show node node47

# Effective job settings and reasons for pending jobs
squeue -u "$USER" -o '%.18i %.12P %.25j %.2t %.10M %.25R'
squeue -u "$USER" -h -o '%i' | head -n 1 | xargs -r scontrol show job

# QoS / account limits and priority snapshot
sacctmgr -nP show qos format=Name,Priority,MaxWall,MaxJobsPU,MaxSubmitJobsPU,MaxTRESPU,GrpTRES
sshare -l -U -u "$USER"
```

For an immediate rejection before allocation of a job ID, preserve the exact `sbatch` error and requested `--partition`, `--account`, `--qos`, `--gpus`, `--cpus-per-task`, `--mem`, `--time` and `--array`. Large job arrays count multiple tasks toward submission caps. Jobs with dependencies may also count as submitted jobs even before running.

For investigating your current usage by QoS, including pending jobs:

```bash
squeue -h -u "$USER" -o '%i|%q|%T|%P|%b|%R'
sacct -u "$USER" --starttime today --format=JobID,JobName,Account,QOS,Partition,State,AllocTRES
```

### Recommended submission defaults

Specify `--account=images`, a GPU partition, and `--qos=normal` explicitly if you intend to use the confirmed `normal` QoS. **Do not automatically use `runfill`** as a way around the 30-job cap: its scheduling behavior and effective rules have not been verified. The shared template below uses `normal` as a known eligible QoS, and its requested runtime of one day fits its named GPU partitions. RTX6000PRO nodes offer **2 GPUs per node**; for multi-GPU jobs, a single-node `--gpus=4` request cannot run there.

---

