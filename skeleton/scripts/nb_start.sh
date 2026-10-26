#!/usr/bin/env bash
# Start a notebook session: submit the JupyterLab + VS Code tunnel job, wait for it, print how to attach.
#   nb_start.sh [--name <name>] [--port <port>] [--no-tunnel]
# Default name "current" is the interactive session the jupyter MCP server attaches to; its tunnel is
# named {{TUNNEL_PREFIX}}-<node number>. Other sessions get no tunnel unless --tunnel-name is given. The first job
# on a given node asks for a one-time GitHub device login; the code is printed below.
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=current; PORT=""; TUNNEL=auto
while [ $# -gt 0 ]; do case "$1" in
  --name) NAME=$2; shift 2;; --port) PORT=$2; shift 2;;
  --no-tunnel) TUNNEL=""; shift;; --tunnel-name) TUNNEL=$2; shift 2;;
  *) echo "unknown arg $1"; exit 1;; esac; done
[ "$TUNNEL" = auto ] && { [ "$NAME" = current ] && TUNNEL={{TUNNEL_PREFIX}} || TUNNEL=""; }
mkdir -p .nb slurm_logs
ENVF=.nb/$NAME.env
if [ -f "$ENVF" ]; then
  . "$ENVF"
  if squeue -h -j "$SLURM_JOB_ID" 2>/dev/null | grep -q .; then
    echo "session '$NAME' already running on $NB_HOST (job $SLURM_JOB_ID)${TUNNEL_NAME:+, tunnel $TUNNEL_NAME}: $JUPYTER_URL/lab?token=$JUPYTER_TOKEN"; exit 0
  fi
fi
scripts/gpus.sh
TOKEN=$(python3 -c "import secrets; print(secrets.token_hex(16))")
JOB=$(sbatch --parsable -A {{SLURM_ACCOUNT}} --gres=gpu:1 --job-name "nb-$NAME" \
      --export=ALL,NB_NAME="$NAME",NB_TOKEN="$TOKEN",NB_PORT="${PORT:-0}",NB_TUNNEL="$TUNNEL" slurm/notebook.sbatch)
echo "submitted job $JOB, waiting for the node..."
rm -f "$ENVF"
for i in $(seq 1 600); do
  if [ -f "$ENVF" ] && grep -q "SLURM_JOB_ID=$JOB" "$ENVF"; then break; fi
  st=$(squeue -h -j "$JOB" -o %T 2>/dev/null || true)
  [ -z "$st" ] && { echo "job $JOB left the queue before starting; see slurm_logs/nb-$NAME-$JOB.out"; exit 1; }
  sleep 3
done
[ -f "$ENVF" ] || { echo "timed out waiting for job $JOB"; exit 1; }
. "$ENVF"
echo
echo "session '$NAME' on $NB_HOST (job $SLURM_JOB_ID)"
if [ -n "$TUNNEL" ]; then
  LOG=slurm_logs/nb-$NAME-$SLURM_JOB_ID.out
  for i in $(seq 1 40); do
    grep -qE "login/device|Open this link|Connected to an existing tunnel|tunnel.*ready|forwarding" "$LOG" 2>/dev/null && break; sleep 3
  done
  if grep -q "login/device" "$LOG" 2>/dev/null; then
    echo "FIRST TIME ON $NB_HOST: $(grep -o 'https://github.com/login/device.*' "$LOG" | head -1)"
    echo "  (the tunnel registers once that is done; later jobs on this node need no login)"
  fi
  echo "VS Code: Remote Explorer > Tunnels > $TUNNEL_NAME  (or https://vscode.dev/tunnel/$TUNNEL_NAME), open folder $PWD"
fi
echo "JupyterLab, in that window's Simple Browser:  $JUPYTER_URL/lab?token=$JUPYTER_TOKEN"
echo "Stop with: scripts/nb_stop.sh --name $NAME"
