# research-template

Scaffolding for a research project driven by Claude Code with notebooks on a Slurm GPU cluster.
Three modes of work share one layout and one Python library:

1. **interactive**: you and the agent in a JupyterLab notebook, kernel on a GPU node;
2. **autoresearch**: an agent alone, one goal, its own notebook job, numbered notebooks;
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

In a separate env named `mcp` (python >= 3.10):

    pip install jupyter-mcp-server

Claude Code itself:

    curl -fsSL https://claude.ai/install.sh | bash

## Layout of a stamped project

    CLAUDE.md        how to work here (project facts + the conventions below)
    RESEARCH.md      what we currently believe, each claim pointing to its notebook/run
    lib/             the one Python library; notebooks and scripts both import it
    notebooks/       interactive sessions, YYYY-MM-DD_short-label.ipynb
    auto/<run>/      autoresearch runs: GOAL.md, LOG.md, notebooks/NN_YYYY-MM-DD_label.ipynb, jobs/
    scripts/         batch entry points and the notebook-session helpers
    slurm/           sbatch files
    .nb/             (ignored) URL and token of the running notebook server

## One-shot cluster bootstrap

    curl -fsSL https://raw.githubusercontent.com/lolismek/research-template/main/cluster_setup.sh -o /tmp/cs.sh
    bash /tmp/cs.sh <project> [conda_env] [cluster_dir]

(or clone this repo there and run `./cluster_setup.sh`). Repos are private, so `gh auth login` or an ssh key
for GitHub is needed on the cluster first.
