#!/bin/bash
#SBATCH -A hewittlab
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=24:00:00
#SBATCH --output=slurm_logs/%x-%j.out
# Notebook session job: JupyterLab (localhost only) + a VS Code tunnel on the same GPU node.
# Claude Code runs on this node (inside the VS Code window attached to the tunnel), so the MCP
# server, the kernel and the browser all talk over localhost. Started by scripts/nb_start.sh,
# which sets NB_NAME, NB_TOKEN, NB_PORT (0 = pick a free port), NB_TUNNEL (empty = no tunnel).
cd {{CLUSTER_DIR}}
source slurm/gpu_guard.sh
export HF_HOME=/scratch/hewittlab/aij2115/hf_cache
PY=~/miniforge3/envs/{{CONDA_ENV}}/bin
VSC=/scratch/hewittlab/aij2115/vscode
export VSCODE_CLI_USE_FILE_KEYCHAIN=1   # store/read the tunnel login in $VSC/cli/token.json, not a per-node keyring
PORT=${NB_PORT:-0}
if [ "$PORT" = 0 ]; then
  PORT=$($PY/python -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1])")
fi
mkdir -p .nb
cat > .nb/${NB_NAME:-current}.env <<ENV
SLURM_JOB_ID=$SLURM_JOB_ID
NB_HOST=$(hostname)
NB_PORT=$PORT
JUPYTER_URL=http://127.0.0.1:$PORT
JUPYTER_TOKEN=$NB_TOKEN
NB_TUNNEL=${NB_TUNNEL:-}
ENV
echo "JupyterLab on $(hostname):$PORT (job $SLURM_JOB_ID)"
$PY/jupyter lab --no-browser --ip 127.0.0.1 --port "$PORT" \
  --IdentityProvider.token "$NB_TOKEN" --ServerApp.root_dir "$PWD" &
JL=$!
if [ -n "${NB_TUNNEL:-}" ]; then
  echo "VS Code tunnel '$NB_TUNNEL'"
  /scratch/hewittlab/aij2115/bin/code tunnel --accept-server-license-terms --name "$NB_TUNNEL" \
    --cli-data-dir $VSC/cli --server-data-dir $VSC/server --extensions-dir $VSC/extensions &
fi
wait $JL
