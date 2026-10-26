#!/usr/bin/env bash
# One-time setup on the cluster login node. Run as: ./cluster_setup.sh <project> [conda_env] [cluster_dir]
# Installs the JupyterLab side into the project env, jupyter-mcp-server into its own env, Claude Code, the
# VS Code CLI, clones the project repo, and links the skill. Reads config.env next to this script.
set -euo pipefail
NAME=${1:?usage: cluster_setup.sh <project> [conda_env] [cluster_dir]}
HERE=$(cd "$(dirname "$0")" && pwd)
CFG=${RESEARCH_TEMPLATE_CONFIG:-$HERE/config.env}
[ -f "$CFG" ] || { echo "missing $CFG: cp $HERE/config.env.example $CFG and fill it in"; exit 1; }
set -a; . "$CFG"; set +a
ENV=${2:-$CONDA_ENV}
CLUSTER_DIR=${3:-$SCRATCH/$NAME}
CONDA_ROOT=${CONDA_ROOT/#\~/$HOME}
CONDA=$CONDA_ROOT/bin/conda
PY=$CONDA_ROOT/envs/$ENV/bin

echo "== JupyterLab + collaboration into env $ENV"
$PY/pip install -q "jupyterlab>=4.4" "jupyter-collaboration>=5" jupyter-mcp-tools ipykernel matplotlib
$PY/python -c "import jupyterlab, jupyter_collaboration; print('jupyterlab', jupyterlab.__version__)"

echo "== jupyter-mcp-server into $SCRATCH/envs/mcp"
[ -d "$SCRATCH/envs/mcp" ] || $CONDA create -y -q -p "$SCRATCH/envs/mcp" python=3.12
"$SCRATCH/envs/mcp/bin/pip" install -q "jupyter-mcp-server>=2.2"
"$SCRATCH/envs/mcp/bin/jupyter-mcp-server" --help | head -3

echo "== VS Code CLI (tunnel) in $SCRATCH/bin"
mkdir -p "$SCRATCH/bin" "$SCRATCH/vscode"
[ -x "$SCRATCH/bin/code" ] || curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" | tar xz -C "$SCRATCH/bin"
"$SCRATCH/bin/code" --version | head -1

echo "== Claude Code"
if ! command -v claude >/dev/null && [ ! -x ~/.local/bin/claude ]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
~/.local/bin/claude --version || true

echo "== skill + project repo"
mkdir -p ~/.claude/skills
ln -sfn "$HERE/skill" ~/.claude/skills/research-project
if [ ! -d "$CLUSTER_DIR" ]; then
  git clone -q "git@github.com:$GITHUB_USER/$NAME" "$CLUSTER_DIR"
fi
mkdir -p "$CLUSTER_DIR"/{runs,data,slurm_logs}
echo
echo "done. Next, on the login node:"
echo "  cd $CLUSTER_DIR && scripts/nb_start.sh        # start the notebook job; first time on a node: enter the printed GitHub device code"
echo "  then attach VS Code to the printed tunnel ($TUNNEL_PREFIX-<node>) and log in to claude there once"
