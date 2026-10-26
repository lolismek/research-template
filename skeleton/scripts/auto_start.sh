#!/usr/bin/env bash
# Launch an autoresearch run as a Slurm job: scripts/auto_start.sh <run>
# Needs auto/<run>/GOAL.md. The job runs JupyterLab + Claude Code headless on a GPU node and writes
# auto/<run>/{LOG.md,notebooks/,jobs/,claude-<jobid>.log}. Watch with: tail -f auto/<run>/LOG.md
set -euo pipefail
cd "$(dirname "$0")/.."
RUN=${1:?usage: auto_start.sh <run>}
[ -f auto/$RUN/GOAL.md ] || { echo "write auto/$RUN/GOAL.md first"; exit 1; }
mkdir -p auto/$RUN/notebooks auto/$RUN/jobs .nb slurm_logs
scripts/gpus.sh
TOKEN=$(python3 -c "import secrets; print(secrets.token_hex(16))")
JOB=$(sbatch --parsable -A {{SLURM_ACCOUNT}} --gres=gpu:1 --job-name "auto-$RUN" \
      --export=ALL,RUN="$RUN",NB_TOKEN="$TOKEN" slurm/auto.sbatch)
echo "submitted autoresearch job $JOB for auto/$RUN; log: slurm_logs/auto-$RUN-$JOB.out"
