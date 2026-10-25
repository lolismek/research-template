#!/bin/bash
#SBATCH -A hewittlab
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=24:00:00
#SBATCH --output=slurm_logs/%x-%j.out
# JupyterLab server for a notebook session. Started by scripts/nb_start.sh, which sets
# NB_NAME, NB_TOKEN, NB_PORT (0 = pick a free port).
cd {{CLUSTER_DIR}}
source slurm/gpu_guard.sh
export HF_HOME=/scratch/hewittlab/aij2115/hf_cache
PY=~/miniforge3/envs/{{CONDA_ENV}}/bin
PORT=${NB_PORT:-0}
if [ "$PORT" = 0 ]; then
  PORT=$($PY/python -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1])")
fi
mkdir -p .nb
cat > .nb/${NB_NAME:-current}.env <<ENV
SLURM_JOB_ID=$SLURM_JOB_ID
NB_HOST=$(hostname)
NB_PORT=$PORT
JUPYTER_URL=http://$(hostname):$PORT
JUPYTER_TOKEN=$NB_TOKEN
ENV
echo "JupyterLab on $(hostname):$PORT (job $SLURM_JOB_ID)"
exec $PY/jupyter lab --no-browser --ip 0.0.0.0 --port "$PORT" \
  --IdentityProvider.token "$NB_TOKEN" --ServerApp.root_dir "$PWD" \
  --ServerApp.allow_remote_access True --ServerApp.allow_origin '*'
