# Télécom Paris GPU cluster hardware and scheduler configuration

## Slurm Partition Resource Table

Sources: [Télécom Paris GPU partitions](https://computing.telecom-paris.fr/docs/user-guide/resources/compute-nodes/#gpu-partitions) (table copied by user), plus `sinfo` / `scontrol show partition` output supplied on 2026-10-10. The table lists *published physical hardware*; runtime limits are taken from Slurm. GPU memory is per GPU, not cumulative. Node ranges are inclusive. `V100-16GB` and `V100-32GB` are subset partitions overlapping the `V100` partition, so **do not add their GPU totals twice**.

| Partition | Nodes | GPUs per node | CPU cores/node | RAM/node | CPU model | Max walltime |
|---|---|---|---:|---|---|---|
| `A100` | `node[01-07]` | 3x A100 40GB | 64 | 384 GB | 2x AMD EPYC 7302 | 1 day |
| `A100` | `node[54-56]` | 3x A100 40GB | 64 | 384 GB | 2x AMD EPYC 7302 | 1 day |
| `A100` | `nodeaudible01` | 8x A100 SXM4 40GB | 96 | 1024 GB | 2x AMD EPYC 74F3 | 1 day |
| `V100 / V100-16GB` | `node[09,11,13,14]` | 2x V100 16GB | 40 | 192 GB | 2x Intel Xeon Silver 4210R | 2 days |
| `V100 / V100-16GB` | `node42` | 2x V100 16GB + 1x V100S 32GB | 48 | 192 GB | 2x Intel Xeon Gold 6136 | 2 days |
| `V100 / V100-32GB` | `node[08,10,12,15]` | 2x V100S 32GB | 40 | 192 GB | 2x Intel Xeon Silver 4210R | 2 days |
| `V100 / V100-32GB` | `node43` | 3x V100S 32GB | 96 | 384 GB | 2x AMD EPYC 7402 | 2 days |
| `P100` | `node[16,18-21]` | 3x P100 16GB | 32 | 64 GB | 2x Intel Xeon Silver 4108 | 2 days |
| `P100` | `node[17,45-46]` | 2x P100 16GB | 80 | 128 GB | 2x Intel Xeon E5-2698 v4 | 2 days |
| `P100` | `node47` | 1x P100 16GB | 80 | 128 GB | 2x Intel Xeon E5-2698 v4 | 2 days |
| `A30` | `node23` | 2x A30 24GB | 32 | 128 GB | 2x Intel Xeon Silver 4108 | 4 days |
| `A40` | `node22` | 2x A40 46GB | 32 | 128 GB | 2x Intel Xeon Silver 4108 | 4 days |
| `A40` | `node[24-38]` | 2x A40 46GB | 40 | 128 GB | 2x Intel Xeon Silver 4210 | 4 days |
| `3090` | `node40` | 3x RTX 3090 24GB | 16 | 128 GB | 1x AMD EPYC 7232P | 2 days |
| `L40S` | `node39` | 4x L40S 46GB | 128 | 512 GB | 2x AMD EPYC 9374F | 1 day |
| `L40S` | `node[50,51,57]` | 4x L40S 46GB | 64 | 384 GB | 2x AMD EPYC 9124 | 1 day |
| `L40S` | `node52` | 8x L40S 46GB | 128 | 1024 GB | 2x AMD EPYC 7543 | 1 day |
| `H100` | `node53` | 4x H100 NVL 94GB | 64 | 768 GB | 2x AMD EPYC 9124 | 1 day |
| `H100` | `nodesumo01` | 2x H100 NVL 94GB | 64 | 384 GB | 2x AMD EPYC 9124 | 1 day |
| `RTX6000PRO` | `node[58-61]` | 2x RTX PRO 6000 96GB | 96 | 256 GB | 2x AMD EPYC 9275F | 1 day |
| `audible` | `nodeaudible02` | 4x A100 SXM4 80GB | 48 | 1024 GB | 2x AMD EPYC 74F3 | 1 day |

CPU-only partitions are not listed in the supplied official GPU table; Slurm reports `CPU` (10 nodes, 4 days) and `cpu-high` (2 nodes, 5 days). Slurm also lists `nodemm[01,05]` under `3090`, but their hardware configuration is not given in the copied official table.

### Published inventory vs live Slurm

| Partition | Published GPUs from listed nodes | Slurm reported GPUs | Notes |
|---|---:|---:|---|
| A100 | 38 | 38 | Matches; 30 standard + 8 on `nodeaudible01` |
| V100 (union) | 22 | 22 | Subpartitions overlap; mixed 16/32 GB node42 |
| P100 | 22 | 24 | Official list says `node47` has 1 GPU; Slurm TRES reports 24; check node-level GRES |
| A30 | 2 | 2 | Matches |
| A40 | 32 | 31 | Official `node22` lists 2 GPUs; Slurm `sinfo` reports 1 GPU there |
| 3090 | 3 on `node40` | 10 across 3 nodes | Slurm includes two `nodemm` nodes not listed in official hardware table |
| L40S | 28 | 24 | Slurm lists `node[39,50-52,57]`, but TRES reports 24; investigate `node52` / node-level GRES |
| H100 | 6 | 6 | Matches |
| RTX6000PRO | 8 | 8 | 4 nodes, each with 2 GPUs |
| audible | 4 | 4 | 80GB A100, distinct from `nodeaudible01` in A100 partition |

These differences should be treated as **inventory vs scheduler configuration discrepancies**, not assumed to be free GPUs or confirmed hardware failures. Inspect `sinfo -N -o '%N|%P|%G|%c|%m|%t'` and `scontrol show node <node>` as needed.

---

