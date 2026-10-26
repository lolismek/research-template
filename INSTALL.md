# Installing the harness (a guide for agents)

You are a Claude Code session asked to set up this template for a person, on a new project, a new
cluster, or a new laptop. Read `README.md` first for what the pieces are. This file is the order of
operations, what each step needs from the human, and how to check it worked. Do the checks; do not
report a step done until its check passes.

## 0. What exists where

| Piece | Where | Who installs |
|---|---|---|
| this template | laptop `~/research-template`, GitHub (public), cluster `$SCRATCH/research-template` | you |
| `config.env` | next to the template on both machines, git-ignored; every site value lives here | you, from the human's answers |
| skill `research-project` | symlink `~/.claude/skills/research-project -> <template>/skill`, both machines | you |
| project repo | laptop `~/<name>`, GitHub private, cluster `<cluster_dir>` | you |
| JupyterLab + collaboration + MCP tools | the project's conda env on the cluster | `cluster_setup.sh` |
| Jupyter MCP Server (Datalayer) | its own env on scratch | `cluster_setup.sh` |
| Claude Code CLI | cluster `~/.local/bin/claude` | `cluster_setup.sh` |
| VS Code CLI (`code tunnel`) | cluster scratch `bin/code`, data under scratch `vscode/` | `cluster_setup.sh` |
| GitHub ssh key on the cluster | `~/.ssh/id_ed25519_github`, added to the person's GitHub account | you generate, human adds (or `gh`) |
| tunnel GitHub login | once per compute node, device code | human |
| Claude Code login | once, inside the tunnel window | human |
| VS Code extensions "Remote - Tunnels" and "Claude Code" | the person's VS Code desktop | human |

## 1. Laptop

1. Clone or confirm `~/research-template`; `ln -sfn ~/research-template/skill ~/.claude/skills/research-project`.
2. `cp config.env.example config.env` inside it and fill every line: login host, Slurm account and
   partition, scratch root (absolute), conda root, default env, GitHub user, tunnel prefix, GPU cap. Ask
   the human for what you cannot read off the cluster (`sacctmgr show assoc user=$USER`, `sinfo`, `conda info`).
   Never commit this file; the template repo is public.
3. Stamp: `~/research-template/new_project.sh <name> [conda_env] [cluster_dir]`. Defaults are
   `CONDA_ENV` and `$SCRATCH/<name>` from the config. The script refuses to finish if a placeholder is left.
4. Fill `CLAUDE.md` (project facts: topic, model, env, paths, hazards, GPU cap) and `RESEARCH.md`
   (what is already known, each line pointing at where it was shown). Ask the human for anything you
   cannot derive.
5. `gh repo create <github-user>/<name> --private --source ~/<name> --push`. Check: `git -C ~/<name> status` clean, `origin` set.

## 2. Cluster, one-time per cluster

Work on scratch, not home: home has a small hidden quota and goes over it easily. Only tiny things
belong in home (Claude Code binary and config, ssh keys, the conda envs that are already there).

1. GitHub access from the cluster: if `ssh -T git@github.com` fails, `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -N ""`,
   add a `Host github.com` block in `~/.ssh/config` with that `IdentityFile`, and give the public key
   to the human to add at github.com/settings/keys (title them by machine). Check: `ssh -T git@github.com` greets the user.
2. `git clone https://github.com/lolismek/research-template $SCRATCH/research-template`, then copy the laptop's
   `config.env` next to it (scp; it is not in git).
3. `$SCRATCH/research-template/cluster_setup.sh <name> [conda_env] [cluster_dir]`.
   It pip-installs `jupyterlab jupyter-collaboration jupyter-mcp-tools ipykernel matplotlib` into the project
   env, creates the `mcp` env on scratch with `jupyter-mcp-server`, installs Claude Code and the VS Code
   CLI, links the skill, clones the project to `<cluster_dir>`, makes `runs/ data/ slurm_logs/`.
   Checks: the project env still imports torch with CUDA (`python -c "import torch, jupyterlab, jupyter_collaboration"`),
   `$SCRATCH/envs/mcp/bin/jupyter-mcp-server --help` works, `~/.local/bin/claude --version`,
   `$SCRATCH/bin/code --version`.
4. Extra Python packages the env lacks: `pip install --target $SCRATCH/pylib <pkg>`; `lib/paths.py` adds that
   directory to `sys.path`. Never `pip install` into home.

## 3. First session (needs the human twice)

1. On the login node: `cd <cluster_dir> && scripts/nb_start.sh`. It checks the GPU cap, submits the job, waits,
   and prints: the tunnel name `<prefix>-<node>`, the JupyterLab URL, and, the first time on a node, a
   GitHub device code. Give the code to the human (github.com/login/device). Check: `slurm_logs/nb-current-<job>.out`
   contains `Open: https://vscode.dev/tunnel/...`, or `code tunnel status` inside the job says `Connected`.
2. `scripts/nb_check.sh` from the login node: JupyterLab answers and the MCP server lists its tools (18 at v2.2).
3. Tell the human: in VS Code desktop, install "Remote - Tunnels", run "Remote-Tunnels: Connect to Tunnel",
   sign in with GitHub, pick the tunnel, open `<cluster_dir>`, install the Claude Code extension on the remote
   and sign in once, paste the JupyterLab URL into Simple Browser (Cmd+Shift+P, "Simple Browser: Show").
4. In that window the first Claude Code start asks to approve the project's `jupyter` MCP server from
   `.mcp.json`; if its tools do not appear, `/mcp`. Round trip: create `notebooks/<date>_hello.ipynb` in
   JupyterLab, ask Claude Code there to insert and run a cell; it must appear live in the tab.

The Claude Code that does notebook work is the one inside the tunnel window, on the node. A session on
the laptop or the login node cannot reach the node's JupyterLab at all.

## 4. Things that bit us (do not rediscover them)

- Compute nodes accept no inbound TCP from the login node or the laptop, and cannot ssh back to the login node.
  Only outbound internet. Hence the tunnel; no relay, port forward or ssh -L will work.
- The tunnel's GitHub token is encrypted with a machine-bound key: a login done on the login node is invisible on
  a compute node. Each node has its own CLI data dir `vscode/cli-<node>` and its own tunnel name.
- Two JupyterLab servers sharing the default `~/.local/share/jupyter` on NFS corrupt each other's sqlite files
  ("disk I/O error" on every save). The sbatch files set a per-session `JUPYTER_DATA_DIR` under `.nb/`.
- `nvidia-smi` is broken on some nodes (driver/library mismatch) while CUDA works; `gpu_guard.sh` measures memory through torch.
- Every job must request a GPU. Record node-specific hazards (bad cards, drained nodes) in the project's `CLAUDE.md`.
- Never touch other users' processes. Stay within the project's GPU cap, counting notebook kernels.
- Sessions, Claude Code conversations included, end with the 24 h job. Files and git survive; `claude --resume` continues.

## 5. Another cluster

Everything site-specific is a `{{PLACEHOLDER}}` in `skeleton/` filled from `config.env` at stamp time, so
a new cluster is a new `config.env` plus a re-run of sections 2 and 3. Things that may still differ and live
in the skeleton itself: the sbatch headers (`--gres=gpu:1`, cpus, memory, 24 h) in `skeleton/slurm/*.sbatch`,
and the GPU-occupancy threshold in `gpu_guard.sh`. If the new cluster allows ssh into allocated nodes, the
tunnel can be replaced by VS Code Remote-SSH with a ProxyJump through the login node, and `.mcp.json` works
unchanged. Never commit cluster names, accounts or usernames to the template; they belong in `config.env`
and in the private project repo's `CLAUDE.md`.
