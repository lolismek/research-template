# {{PROJECT}}

Research project stamped from `~/research-template`. Read `RESEARCH.md` before starting any work.

## Project facts
- Cluster: Columbia AICS, `ssh aij2115@aics.cs.columbia.edu`. Work dir `{{CLUSTER_DIR}}` (this repo).
- Conda env `{{CONDA_ENV}}` (`~/miniforge3/envs/{{CONDA_ENV}}`). HF cache `/scratch/hewittlab/aij2115/hf_cache`.
- Slurm: `sbatch -A hewittlab --gres=gpu:1`, every job requests a GPU, partition max 24h.
- GPU cap: 4 cards at a time across everything (notebook kernels + batch jobs). Run `scripts/gpus.sh` first.
- Models never run on the laptop. Heavy linear algebra runs in torch on the GPU, not numpy.
- Known hazards: see `slurm/gpu_guard.sh` (occupied or faulty cards get resubmitted).

## Three modes
1. **Interactive notebook** (user + agent). `scripts/nb_start.sh` -> JupyterLab in a one-GPU job,
   `.nb/current.env` holds URL + token, the `jupyter` MCP server uses it. Notebooks in `notebooks/`,
   one per question, `YYYY-MM-DD_short-label.ipynb`. Cell 1 is imports + loading, run once.
   Markdown cell at the top states the question; a closing markdown cell states what was found.
2. **Autoresearch** (agent alone). `auto/<run>/` with `GOAL.md`, `LOG.md`, `notebooks/NN_YYYY-MM-DD_label.ipynb`,
   `jobs/`. Own notebook job via `scripts/nb_start.sh --name <run>`; never the user's kernel.
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
