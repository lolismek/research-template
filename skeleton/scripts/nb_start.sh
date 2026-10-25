#!/usr/bin/env bash
# Start a notebook session: submit the JupyterLab job, wait for it, write .nb/<name>.env,
# start a login-node relay so localhost:<port> reaches the compute node, print the URL.
#   nb_start.sh [--name <name>] [--port <port>]
# Default name "current" is the interactive session the jupyter MCP server attaches to.
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=current; PORT=""
while [ $# -gt 0 ]; do case "$1" in
  --name) NAME=$2; shift 2;; --port) PORT=$2; shift 2;; *) echo "unknown arg $1"; exit 1;; esac; done
mkdir -p .nb slurm_logs
ENVF=.nb/$NAME.env
if [ -f "$ENVF" ]; then
  . "$ENVF"
  if squeue -h -j "$SLURM_JOB_ID" 2>/dev/null | grep -q .; then
    echo "session '$NAME' already running (job $SLURM_JOB_ID): $JUPYTER_URL/lab?token=$JUPYTER_TOKEN"; exit 0
  fi
fi
scripts/gpus.sh
TOKEN=$(python3 -c "import secrets; print(secrets.token_hex(16))")
JOB=$(sbatch --parsable -A hewittlab --gres=gpu:1 --job-name "nb-$NAME" \
      --export=ALL,NB_NAME="$NAME",NB_TOKEN="$TOKEN",NB_PORT="${PORT:-0}" slurm/notebook.sbatch)
echo "submitted job $JOB, waiting for JupyterLab..."
rm -f "$ENVF"
for i in $(seq 1 600); do
  if [ -f "$ENVF" ] && grep -q "SLURM_JOB_ID=$JOB" "$ENVF"; then break; fi
  st=$(squeue -h -j "$JOB" -o %T 2>/dev/null || true)
  [ -z "$st" ] && { echo "job $JOB left the queue before starting; see slurm_logs/nb-$NAME-$JOB.out"; exit 1; }
  sleep 3
done
[ -f "$ENVF" ] || { echo "timed out waiting for job $JOB"; exit 1; }
. "$ENVF"
# login-node relay: localhost:$NB_PORT -> $NB_HOST:$NB_PORT, so VS Code / a tunnel can use localhost
RELAY_PID=$(pgrep -f "nb_relay.py $NB_PORT " || true)
if [ -z "$RELAY_PID" ]; then
  nohup python3 scripts/nb_relay.py "$NB_PORT" "$NB_HOST" "$NB_PORT" >> slurm_logs/nb-relay-$NAME.log 2>&1 &
  echo "RELAY_PID=$!" >> "$ENVF"
fi
echo
echo "JupyterLab (from the login node or VS Code Remote-SSH):  http://localhost:$NB_PORT/lab?token=$JUPYTER_TOKEN"
echo "From the laptop without VS Code:  ssh -N -L $NB_PORT:localhost:$NB_PORT aij2115@aics.cs.columbia.edu   then open the same URL"
echo "Stop with: scripts/nb_stop.sh --name $NAME"
