#!/bin/bash
#SBATCH -A hewittlab
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=24:00:00
#SBATCH --output=slurm_logs/%x-%j.out
# Autoresearch job: JupyterLab (localhost) + Claude Code headless on the same GPU node, working on
# auto/<run>/. Started by scripts/auto_start.sh, which sets RUN, NB_TOKEN. The laptop can be closed.
cd {{CLUSTER_DIR}}
source slurm/gpu_guard.sh
export HF_HOME=/scratch/hewittlab/aij2115/hf_cache
export PATH=~/.local/bin:$PATH
PY=~/miniforge3/envs/{{CONDA_ENV}}/bin
NAME=auto-${RUN:?set RUN}
PORT=$($PY/python -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1])")
mkdir -p .nb
cat > .nb/$NAME.env <<ENV
SLURM_JOB_ID=$SLURM_JOB_ID
NB_HOST=$(hostname)
NB_PORT=$PORT
JUPYTER_URL=http://127.0.0.1:$PORT
JUPYTER_TOKEN=$NB_TOKEN
ENV
$PY/jupyter lab --no-browser --ip 127.0.0.1 --port "$PORT" \
  --IdentityProvider.token "$NB_TOKEN" --ServerApp.root_dir "$PWD" &
JL=$!
sleep 15
export NB_SESSION=$NAME
PROMPT="Autoresearch run '$RUN'. Read CLAUDE.md, RESEARCH.md, auto/$RUN/GOAL.md and auto/$RUN/LOG.md (if any).
Work only through the jupyter MCP server (session $NAME is already running; notebooks are files under
auto/$RUN/notebooks/, one per attempt, named NN_YYYY-MM-DD_label.ipynb). Batch jobs you need go in
auto/$RUN/jobs/ and are submitted with sbatch; respect the GPU cap in CLAUDE.md. After each attempt append one
entry to auto/$RUN/LOG.md and commit. Stop when the bar in GOAL.md is met or your ideas are exhausted, and end
LOG.md with a proposed one-line entry for RESEARCH.md. Nothing is run on the user's own kernel."
claude -p "$PROMPT" --dangerously-skip-permissions --output-format text \
  > auto/$RUN/claude-$SLURM_JOB_ID.log 2>&1
echo "claude exited with $? (job $SLURM_JOB_ID)"
kill $JL 2>/dev/null; rm -f .nb/$NAME.env
