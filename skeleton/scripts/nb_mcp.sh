#!/usr/bin/env bash
# MCP launcher used by .mcp.json: reads the running notebook session and starts jupyter-mcp-server
# against it over stdio. NB_SESSION selects a non-default session (e.g. an autoresearch run).
set -euo pipefail
cd "$(dirname "$0")/.."
ENVF=.nb/${NB_SESSION:-current}.env
if [ ! -f "$ENVF" ]; then
  echo "no notebook session running; start one with scripts/nb_start.sh" >&2; exit 1
fi
. "$ENVF"
export JUPYTER_URL JUPYTER_TOKEN ALLOW_IMG_OUTPUT=true
exec ~/miniforge3/envs/mcp/bin/jupyter-mcp-server --transport stdio
