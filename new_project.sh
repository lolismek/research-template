#!/usr/bin/env bash
# Stamp a new research project from the skeleton.
#   new_project.sh <name> [conda_env] [cluster_dir]
# Site values (Slurm account, scratch root, conda, GitHub user, ...) come from config.env next to this
# script (copy config.env.example and fill it in).
set -euo pipefail
NAME=${1:?usage: new_project.sh <name> [conda_env] [cluster_dir]}
HERE=$(cd "$(dirname "$0")" && pwd)
CFG=${RESEARCH_TEMPLATE_CONFIG:-$HERE/config.env}
[ -f "$CFG" ] || { echo "missing $CFG: cp $HERE/config.env.example $CFG and fill it in"; exit 1; }
set -a; . "$CFG"; set +a
ENV=${2:-$CONDA_ENV}
CLUSTER_DIR=${3:-$SCRATCH/$NAME}
DEST=~/$NAME
[ -e "$DEST" ] && { echo "$DEST exists"; exit 1; }
cp -R "$HERE/skeleton" "$DEST"
cd "$DEST"
for f in CLAUDE.md RESEARCH.md scripts/*.sh slurm/*.sbatch slurm/*.sh lib/*.py .mcp.json; do
  sed -i.bak -e "s|{{PROJECT}}|$NAME|g" -e "s|{{CONDA_ENV}}|$ENV|g" -e "s|{{CLUSTER_DIR}}|$CLUSTER_DIR|g" \
    -e "s|{{SCRATCH}}|$SCRATCH|g" -e "s|{{SLURM_ACCOUNT}}|$SLURM_ACCOUNT|g" -e "s|{{SLURM_PARTITION}}|$SLURM_PARTITION|g" \
    -e "s|{{CONDA_ROOT}}|$CONDA_ROOT|g" -e "s|{{CLUSTER_HOST}}|$CLUSTER_HOST|g" -e "s|{{TUNNEL_PREFIX}}|$TUNNEL_PREFIX|g" \
    -e "s|{{GPU_CAP}}|$GPU_CAP|g" "$f"
  rm -f "$f.bak"
done
if grep -rn '{{' . --exclude-dir=.git | grep -v README.md; then echo "unfilled placeholders above"; exit 1; fi
chmod +x scripts/*.sh
git init -q && git add -A && git commit -qm "scaffold from research-template"
echo "created $DEST"
echo "next: edit CLAUDE.md and RESEARCH.md, then: gh repo create $GITHUB_USER/$NAME --private --source=$DEST --push"
