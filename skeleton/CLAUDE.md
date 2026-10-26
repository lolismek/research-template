# {{PROJECT}}

Research project stamped from `~/research-template`. Read `RESEARCH.md` before starting any work.

## Project facts
- Cluster: Columbia AICS, `ssh aij2115@aics.cs.columbia.edu`. Work dir `{{CLUSTER_DIR}}` (this repo).
- Conda env `{{CONDA_ENV}}` (`~/miniforge3/envs/{{CONDA_ENV}}`). HF cache `/scratch/hewittlab/aij2115/hf_cache`.
  Extra packages not in the env go to `/scratch/hewittlab/aij2115/pylib` (`pip install --target`, home is
  over quota); `lib.paths` puts it on `sys.path`. Paths come from `lib.paths`, never hard-coded in notebooks.
- Slurm: `sbatch -A hewittlab --gres=gpu:1`, every job requests a GPU, partition max 24h.
- GPU cap: 4 cards at a time across everything (notebook kernels + batch jobs). Run `scripts/gpus.sh` first.
- Models never run on the laptop. Heavy linear algebra runs in torch on the GPU, not numpy.
- Known hazards: see `slurm/gpu_guard.sh` (occupied or faulty cards get resubmitted).

## Three modes
1. **Interactive notebook** (user + agent). `scripts/nb_start.sh` -> one-GPU job running JupyterLab
   (localhost) and a VS Code tunnel `aics-nb-<node>`. The user attaches VS Code to the tunnel, so Claude Code,
   the `jupyter` MCP server (reads `.nb/current.env`), the kernel and the browser are all on that node.
   Notebooks in `notebooks/`,
   one per question, `YYYY-MM-DD_short-label.ipynb`. Cell 1 is imports + loading, run once.
   Markdown cell at the top states the question; a closing markdown cell states what was found.
   **Sidecar** (short compute for a notebook, < ~30 min): a thin `scripts/` script importing `lib/`, run as a
   background process on the notebook node and its GPU (no sbatch, no extra card), so the kernel stays free.
   Output is a cache in `data/<topic>/` that the notebook loads, each result saved with its full config;
   log to `logs/<script>_<args>.log`. Dies with the notebook job (and possibly the Claude session), so anything
   longer or needing its own GPU goes to mode 3.
2. **Autoresearch** (agent alone). `auto/<run>/` with `GOAL.md`, `LOG.md`, `notebooks/NN_YYYY-MM-DD_label.ipynb`,
   `jobs/`. Launched with `scripts/auto_start.sh <run>`: a job running its own JupyterLab plus Claude Code
   headless, so it keeps going with the laptop closed. Never the user's kernel.
3. **Batch** (long or multi-GPU). Thin script in `scripts/` importing `lib/`, sbatch copied from
   `slurm/job.sbatch`, outputs to `runs/<date>_<label>/` on scratch with `config.json`.
   Results are loaded into a notebook for inspection, not pasted into chat.

## Conventions
- `lib/` is the only home for experiment logic. Notebooks and scripts import it; nothing is duplicated.
- Edit an existing notebook when returning to its question. New notebook only for a new question.
- No loose figure files; plots stay inline in notebooks. Commit notebooks with outputs.
- Settled findings: one line in `RESEARCH.md` with a pointer to the notebook or run. Detail in the notebook or `auto/<run>/LOG.md`.
- Commit as you go. No Co-Authored-By or session trailers in commit messages.
- Run only what was asked for in chat; no extra experiments or arms.
