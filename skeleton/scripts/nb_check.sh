#!/usr/bin/env bash
# Verify a running notebook session end to end: JupyterLab answers, and the jupyter MCP server starts and lists
# its tools. Run from the login node (it hops into the job with srun --overlap) or on the node itself.
#   scripts/nb_check.sh [--name <session>]
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=current; [ "${1:-}" = "--name" ] && NAME=$2
ENVF=.nb/$NAME.env; [ -f "$ENVF" ] || { echo "no session '$NAME'"; exit 1; }
. "$ENVF"
if [ "$(hostname)" != "$NB_HOST" ]; then
  exec srun --jobid="$SLURM_JOB_ID" --overlap bash "$0" --name "$NAME"
fi
echo "session '$NAME' on $NB_HOST, job $SLURM_JOB_ID"
curl -sS -m 10 "$JUPYTER_URL/api/status?token=$JUPYTER_TOKEN" >/dev/null && echo "JupyterLab: ok" || { echo "JupyterLab: NOT answering"; exit 1; }
ERR=$(mktemp)
printf '%s\n' \
 '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"nb_check","version":"0"}}}' \
 '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
 '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
 | NB_SESSION=$NAME timeout 120 scripts/nb_mcp.sh 2>"$ERR" | python3 -c '
import sys, json
ok = False
for l in sys.stdin:
    l = l.strip()
    if not l.startswith("{"): continue
    m = json.loads(l)
    if m.get("id") == 2:
        t = [x["name"] for x in m["result"]["tools"]]; ok = True
        print(f"MCP server: ok, {len(t)} tools:", ", ".join(t))
sys.exit(0 if ok else 1)' || { echo "MCP server: FAILED"; tail -5 "$ERR"; exit 1; }
rm -f "$ERR"
