# research-template

Scaffolding for research projects where Claude Code and a human work together in Jupyter notebooks on
a Slurm GPU cluster. This file explains what the harness does and why, from the ground up, then how to
use it. The working habits come from Goodfire's "You and your research agent"
(goodfire.com/blog/you-and-your-research-agent); the plumbing is ours.

## 1. The problem

Driving experiments from a terminal keeps you far from the tensors: the agent runs scripts, reports
numbers in chat, and you never see the intermediate state or a plot. The fix is to put the work in a
live notebook that both of you can see and edit, with the kernel holding the model between turns.
Two obstacles: the GPUs are on a cluster whose compute nodes accept no inbound connections, and every
new project would otherwise reinvent its layout. The template answers both.

## 2. One project is one git repo

`new_project.sh` copies `skeleton/` into `~/<name>`, fills in the project name, conda env and cluster
work dir, and makes the first commit. The repo lives in three places: the laptop (editing), GitHub
(private), and scratch on the cluster, which is the copy where everything runs. Inside it:

    CLAUDE.md        facts about this project (env, paths, model, GPU cap) and the working rules; the agent reads it first
    RESEARCH.md      what we currently believe, one line per finding, each pointing at the notebook or run that showed it
    lib/             the one Python library; all experiment logic lives here, notebooks and scripts import it
    lib/paths.py     where data, caches and runs live on the cluster; nothing is hard-coded in notebooks
    notebooks/       interactive sessions, one notebook per question, YYYY-MM-DD_short-label.ipynb
    auto/<run>/      autoresearch runs: GOAL.md, LOG.md, notebooks/NN_YYYY-MM-DD_label.ipynb, jobs/
    scripts/         batch and sidecar entry points, plus the session helpers (nb_start, nb_stop, auto_start, gpus)
    slurm/           sbatch files (notebook.sbatch, auto.sbatch, job.sbatch) and gpu_guard.sh
    data/ logs/ runs/   (ignored) sidecar caches and logs, batch outputs; all on scratch
    .nb/             (ignored) URL, token and Jupyter state of each running notebook server

Rules that travel with every project live in `skeleton/CLAUDE.md`, not in global Claude settings,
because they make no sense for a software project. The skill in `skill/` only tells Claude Code that
this template exists and when to reach for it.

## 3. Getting onto a GPU node

`scripts/nb_start.sh` submits a one-GPU Slurm job. On the node the job starts two things:

- **JupyterLab**, listening on localhost only, with a random token written to `.nb/current.env`;
- a **VS Code tunnel**. The node cannot be reached from outside, but it may connect outward. The
  `code tunnel` CLI opens a long-lived connection from the node to Microsoft's relay and registers
  under a name (`aics-nb-<node number>`). VS Code on the laptop connects to the same relay, the relay
  joins the two, and VS Code's server, and so the Claude Code extension, run on the node as if you had
  ssh'd in. A GitHub login ties both ends to you; the login token is encrypted per machine, so the
  first job on each node prints a one-time device code.

The result is one VS Code window with the Claude Code panel on one side and JupyterLab in VS Code's
Simple Browser on the other, everything on the same node, talking over localhost.

## 4. How the agent edits the notebook live

Three pieces, each from someone else:

- **jupyter-collaboration** (the Jupyter project): an open notebook becomes a shared document kept in
  the server's memory; every connected client receives each change as it happens. It was built so two
  humans could edit one notebook at once (CRDTs via the Yjs library).
- **Jupyter MCP Server** (Datalayer): connects to that shared document as one more client and exposes
  insert / edit / run / read-cell as tools. The project's `.mcp.json` points Claude Code at
  `scripts/nb_mcp.sh`, which reads `.nb/<session>.env` and starts the server over stdio.
- **MCP** (Anthropic): the protocol Claude Code uses to talk to external tools.

So a cell the agent inserts is an edit to the same live document your tab is watching, and the kernel
belongs to the notebook on the server, so cells run by either of you execute in one process.

## 5. Four ways of running work

1. **Interactive** (you + agent): one notebook per question under `notebooks/`. The top markdown cell
   states the question, cell 1 loads everything and is run once, then talk and run a few cells, repeat.
   Return to an existing notebook rather than making a near copy. A closing markdown cell says what
   was found.
2. **Sidecar** (short compute, under about 30 min): a thin script in `scripts/` importing `lib/`, run as
   a background process on the notebook node and its GPU so the kernel stays free. It caches to
   `data/<topic>/` with its full config and logs to `logs/`; the notebook loads the cache. It dies with
   the notebook job.
3. **Batch** (long or multi-GPU): a thin script submitted through a copy of `slurm/job.sbatch`, writing
   to `runs/<date>_<label>/` with a `config.json`. Results are inspected in a notebook, not in chat.
4. **Autoresearch** (agent alone): write `auto/<run>/GOAL.md`, then `scripts/auto_start.sh <run>`
   submits a job that starts its own JupyterLab and Claude Code headless. It works through numbered
   notebooks, appends one `LOG.md` entry per attempt, submits batch jobs as needed, commits as it goes,
   and keeps running with the laptop closed. It never touches the user's kernel.

## 6. Guard rails

`scripts/gpus.sh` shows cards held against the cap before any submission. `slurm/gpu_guard.sh` runs at
the start of every job and resubmits elsewhere if the card is occupied by a foreign process or fails a
CUDA check (it measures through CUDA, since nvidia-smi is broken on some nodes). Each notebook server
keeps its Jupyter state under `.nb/`, because the default shared-NFS location corrupts when two servers
run at once. Everything is committed as it happens, so the repo is the record. Sessions end with the
24-hour job; `claude --resume` the next day continues the conversation.

## 7. What came from Goodfire

Notebooks as the unit of work; one notebook per question, dated and labelled, code + results + prose in
one file, edited rather than duplicated; heavy setup in cell 1, then alternate talking and running a
few cells; human review as the bottleneck, so results stay inline as plots and small tables; a separate
autoresearch mode with its own notebooks and log; a shared record of what is known (`RESEARCH.md`).

## How to use it

### Stamp a new project

    ~/research-template/new_project.sh <name> [conda_env] [cluster_dir]

Then edit `CLAUDE.md` (project facts) and `RESEARCH.md` (what is known), create a private GitHub repo,
push, and clone it on the cluster.

### Install the skill (laptop and cluster)

    ln -s ~/research-template/skill ~/.claude/skills/research-project

### Cluster side, once per cluster

    git clone git@github.com:lolismek/research-template /scratch/hewittlab/aij2115/research-template
    /scratch/hewittlab/aij2115/research-template/cluster_setup.sh <project> [conda_env] [cluster_dir]

That installs, by hand if you prefer: `jupyterlab jupyter-collaboration jupyter-mcp-tools ipykernel`
into the project env; `jupyter-mcp-server` into its own env at `/scratch/hewittlab/aij2115/envs/mcp`;
Claude Code (`curl -fsSL https://claude.ai/install.sh | bash`); the VS Code CLI into
`/scratch/hewittlab/aij2115/bin` (`curl -sL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" | tar xz`).
Repos are private, so an ssh key for GitHub is needed on the cluster first. Extra Python packages go to
`/scratch/hewittlab/aij2115/pylib` via `pip install --target`; `lib/paths.py` adds it to `sys.path`.

### A session

    cd /scratch/hewittlab/aij2115/<project>
    scripts/nb_start.sh            # prints the tunnel name, the JupyterLab URL, and a device code the first time on a node

In VS Code: Remote-Tunnels: Connect to Tunnel (extension "Remote - Tunnels"), pick the tunnel, open the
project folder, paste the URL into Simple Browser, sign in to Claude Code once. `scripts/nb_stop.sh`
ends the session.
