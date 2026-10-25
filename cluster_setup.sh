#!/usr/bin/env bash
# One-time setup on the cluster login node. Run as: ./cluster_setup.sh <project> [conda_env] [cluster_dir]
# Installs the JupyterLab side into the project env, jupyter-mcp-server into its own env, Claude Code,
# clones the template (for the skill) and the project repo, and links the skill.
set -euo pipefail
NAME=${1:?usage: cluster_setup.sh <project> [conda_env] [cluster_dir]}
ENV=${2:-sftrl}
CLUSTER_DIR=${3:-/scratch/hewittlab/aij2115/$NAME}
CONDA=~/miniforge3/bin/conda
PY=~/miniforge3/envs/$ENV/bin

echo "== JupyterLab + collaboration into env $ENV"
$PY/pip install -q "jupyterlab>=4.4" "jupyter-collaboration>=5" jupyter-mcp-tools ipykernel matplotlib
$PY/python -c "import jupyterlab, jupyter_collaboration; print('jupyterlab', jupyterlab.__version__)"

echo "== jupyter-mcp-server into env mcp"
[ -d /scratch/hewittlab/aij2115/envs/mcp ] || $CONDA create -y -q -p /scratch/hewittlab/aij2115/envs/mcp python=3.12
/scratch/hewittlab/aij2115/envs/mcp/bin/pip install -q "jupyter-mcp-server>=2.2"
/scratch/hewittlab/aij2115/envs/mcp/bin/jupyter-mcp-server --help | head -3

echo "== VS Code CLI (tunnel) on scratch"
mkdir -p /scratch/hewittlab/aij2115/bin /scratch/hewittlab/aij2115/vscode/cli
[ -x /scratch/hewittlab/aij2115/bin/code ] || curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" | tar xz -C /scratch/hewittlab/aij2115/bin
/scratch/hewittlab/aij2115/bin/code --version | head -1

echo "== Claude Code"
if ! command -v claude >/dev/null && [ ! -x ~/.local/bin/claude ]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
~/.local/bin/claude --version || true

echo "== repos"
TPL=/scratch/hewittlab/aij2115/research-template; [ -d $TPL ] || git clone -q git@github.com:lolismek/research-template $TPL
mkdir -p ~/.claude/skills
ln -sfn $TPL/skill ~/.claude/skills/research-project
if [ ! -d "$CLUSTER_DIR" ]; then
  git clone -q "git@github.com:lolismek/$NAME" "$CLUSTER_DIR"
fi
mkdir -p "$CLUSTER_DIR"/{runs,data,slurm_logs}
echo
echo "done. Next, on the login node:"
echo "  cd $CLUSTER_DIR && scripts/nb_start.sh        # start the notebook job; first time on a node: enter the printed GitHub device code"
echo "  then attach VS Code to the printed tunnel (aics-nb-<node>) and log in to claude there once"
