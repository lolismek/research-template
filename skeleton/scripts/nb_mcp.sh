#!/usr/bin/env bash
# MCP launcher used by .mcp.json: reads the running notebook session and starts jupyter-mcp-server
# against it over stdio. NB_SESSION selects a non-default session (e.g. an autoresearch run).
# JupyterLab listens on localhost of its GPU node, so this must run on that node (Claude Code in the
# VS Code tunnel window, or the autoresearch job itself).
set -euo pipefail
cd "$(dirname "$0")/.."
ENVF=.nb/${NB_SESSION:-${NB_NAME:-current}}.env
if [ ! -f "$ENVF" ]; then
  echo "no notebook session running; start one with scripts/nb_start.sh" >&2; exit 1
fi
. "$ENVF"
if [ "$(hostname)" != "$NB_HOST" ]; then
  echo "session '${NB_SESSION:-current}' runs on $NB_HOST, this is $(hostname); attach VS Code to its tunnel" >&2; exit 1
fi
export JUPYTER_URL JUPYTER_TOKEN ALLOW_IMG_OUTPUT=true
exec {{SCRATCH}}/envs/mcp/bin/jupyter-mcp-server --transport stdio
