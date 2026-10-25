#!/usr/bin/env bash
# Stamp a new research project from the skeleton.
#   new_project.sh <name> [conda_env] [cluster_dir]
set -euo pipefail
NAME=${1:?usage: new_project.sh <name> [conda_env] [cluster_dir]}
ENV=${2:-sftrl}
CLUSTER_DIR=${3:-/scratch/hewittlab/aij2115/$NAME}
HERE=$(cd "$(dirname "$0")" && pwd)
DEST=~/$NAME
[ -e "$DEST" ] && { echo "$DEST exists"; exit 1; }
cp -R "$HERE/skeleton" "$DEST"
cd "$DEST"
for f in CLAUDE.md RESEARCH.md scripts/*.sh slurm/*.sbatch .mcp.json; do
  sed -i.bak -e "s|{{PROJECT}}|$NAME|g" -e "s|{{CONDA_ENV}}|$ENV|g" -e "s|{{CLUSTER_DIR}}|$CLUSTER_DIR|g" "$f"
  rm -f "$f.bak"
done
chmod +x scripts/*.sh
git init -q && git add -A && git commit -qm "scaffold from research-template"
echo "created $DEST"
echo "next: edit CLAUDE.md and RESEARCH.md, then: gh repo create $NAME --private --source=$DEST --push"
