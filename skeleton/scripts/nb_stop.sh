#!/usr/bin/env bash
# Stop a notebook session: cancel its job and relay, remove its env file.
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=current
[ "${1:-}" = "--name" ] && NAME=$2
ENVF=.nb/$NAME.env
[ -f "$ENVF" ] || { echo "no session '$NAME'"; exit 0; }
. "$ENVF"
scancel "$SLURM_JOB_ID" 2>/dev/null || true
[ -n "${RELAY_PID:-}" ] && kill "$RELAY_PID" 2>/dev/null || true
rm -f "$ENVF"
echo "stopped session '$NAME' (job $SLURM_JOB_ID)"
