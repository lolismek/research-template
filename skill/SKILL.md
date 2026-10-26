---
name: research-project
description: Use when starting a new research project (ML experiments on the Slurm cluster, notebook-driven), or when asked how a research project should be laid out, or how to run an interactive notebook session, an autoresearch run, or a batch job inside such a project. Points at ~/research-template.
---

# research-project

A research project here is stamped from `~/research-template` and has three modes of work
that share one layout and one Python library. Read the project's `CLAUDE.md` first; it has
the project facts (env, paths, model). This skill only says what the template is and when to
use it.

## New project

    ~/research-template/new_project.sh <name> [conda_env] [cluster_dir]

Then fill in `CLAUDE.md` (project facts) and `RESEARCH.md` (what is known, with pointers),
create a private GitHub repo and push, clone on the cluster. Do not reuse this for software
engineering projects; it is for experiment-driven research only.

## The three modes

- **interactive**: `scripts/nb_start.sh` submits a one-GPU Slurm job running JupyterLab on
  localhost plus a VS Code tunnel named `aics-nb-<node number>`, and writes `.nb/current.env`. The user attaches
  VS Code to that tunnel, so you (Claude Code), the `jupyter` MCP server (see `.mcp.json`, reads the
  env file), the kernel and the user's browser view all sit on the same node. The MCP server gives
  you insert/execute/read tools on the live notebook. One notebook per question in
  `notebooks/`, named `YYYY-MM-DD_short-label.ipynb`. Cell 1 = imports and loading, run once.
  Run a few cells, discuss, continue. Edit an existing notebook rather than making a near copy.
  Short compute (< ~30 min) that would block the kernel runs as a **sidecar**: a thin `scripts/`
  script started as a background process on the notebook node's own GPU, caching to `data/<topic>/`
  with its full config and logging to `logs/`; the notebook loads the cache. Longer work is batch.
- **autoresearch**: `auto/<run>/` with `GOAL.md`, `LOG.md`, `notebooks/NN_YYYY-MM-DD_label.ipynb`,
  `jobs/`. Launched as its own job with `scripts/auto_start.sh <run>` (JupyterLab + Claude Code
  headless on a GPU node, runs with the laptop closed), never the user's kernel.
  One LOG.md entry per attempt. Propose one line for RESEARCH.md at the end.
- **batch**: thin script in `scripts/` importing `lib/`, sbatch in `slurm/` (copy
  `slurm/job.sbatch`), outputs under `runs/<date>_<label>/` on scratch with a `config.json`.
  Results are inspected in a notebook, not in chat.

## Rules that travel with the template

- Check `scripts/gpus.sh` before any submission; stay within the project's GPU cap.
- Models never run on the laptop.
- `lib/` is the only place for experiment logic; notebooks and scripts import it.
- Settled findings go to `RESEARCH.md` with a pointer to the notebook or run.
