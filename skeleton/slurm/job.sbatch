#!/bin/bash
#SBATCH -A {{SLURM_ACCOUNT}}
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=12:00:00
#SBATCH --output=slurm_logs/%x-%j.out
# Template for a batch job. Copy, rename, fill in the command. Outputs go to runs/<date>_<label>/.
cd {{CLUSTER_DIR}}
source slurm/gpu_guard.sh
export HF_HOME={{SCRATCH}}/hf_cache
PY={{CONDA_ROOT}}/envs/{{CONDA_ENV}}/bin/python
RUN=runs/$(date +%Y-%m-%d)_${LABEL:?set LABEL via --export}
mkdir -p "$RUN"
echo "$0 $@ (job $SLURM_JOB_ID)" > "$RUN/command.txt"
$PY scripts/CHANGE_ME.py --out "$RUN" "$@"
