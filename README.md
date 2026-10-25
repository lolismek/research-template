# research-template

Scaffolding for a research project driven by Claude Code with notebooks on a Slurm GPU cluster.
Three modes of work share one layout and one Python library:

1. **interactive**: you and the agent in a JupyterLab notebook, everything on one GPU node reached
   through a VS Code tunnel (Claude Code panel beside JupyterLab in VS Code's Simple Browser);
2. **autoresearch**: an agent alone, one goal, its own job with JupyterLab + headless Claude Code;
3. **batch**: scripts submitted as Slurm jobs for long or multi-GPU work.

## Stamp a new project

    ~/research-template/new_project.sh <name> [conda_env] [cluster_dir]

creates `~/<name>` as a git repo from `skeleton/`, with placeholders filled in. Then edit
`CLAUDE.md` (project facts) and `RESEARCH.md` (what is known) and push it to GitHub.
Clone the same repo on the cluster; that copy is where Claude Code runs.

## Install the skill

    ln -s ~/research-template/skill ~/.claude/skills/research-project

The skill tells Claude Code that this template exists and when to use it.

## Cluster side, once per cluster

In the project's conda env:

    pip install jupyterlab jupyter-collaboration jupyter-mcp-tools ipykernel

In a separate env on scratch, `/scratch/hewittlab/aij2115/envs/mcp` (python >= 3.10):

    pip install jupyter-mcp-server

Claude Code itself:

    curl -fsSL https://claude.ai/install.sh | bash

VS Code CLI (for the tunnel), on scratch, logged in once with GitHub:

    curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" | tar xz -C /scratch/hewittlab/aij2115/bin
    /scratch/hewittlab/aij2115/bin/code tunnel user login --provider github --cli-data-dir /scratch/hewittlab/aij2115/vscode/cli

Compute nodes allow no inbound ssh, so the tunnel (outbound only) is the way into a job's node.

## Layout of a stamped project

    CLAUDE.md        how to work here (project facts + the conventions below)
    RESEARCH.md      what we currently believe, each claim pointing to its notebook/run
    lib/             the one Python library; notebooks and scripts both import it
    notebooks/       interactive sessions, YYYY-MM-DD_short-label.ipynb
    auto/<run>/      autoresearch runs: GOAL.md, LOG.md, notebooks/NN_YYYY-MM-DD_label.ipynb, jobs/
    scripts/         batch entry points and the session helpers (nb_start/nb_stop/auto_start/gpus)
    slurm/           sbatch files (notebook.sbatch, auto.sbatch, job.sbatch, gpu_guard.sh)
    .nb/             (ignored) URL and token of the running notebook server

## One-shot cluster bootstrap

    git clone git@github.com:lolismek/research-template /scratch/hewittlab/aij2115/research-template
    /scratch/hewittlab/aij2115/research-template/cluster_setup.sh <project> [conda_env] [cluster_dir]

(or clone this repo there and run `./cluster_setup.sh`). Repos are private, so `gh auth login` or an ssh key
for GitHub is needed on the cluster first.
