Autoresearch runs, one folder per goal:

    auto/<run>/GOAL.md                          question, bar for success, what is off limits
    auto/<run>/LOG.md                           one short entry per attempt, pointing to its notebook
    auto/<run>/notebooks/NN_YYYY-MM-DD_label.ipynb   one per attempt, numbered so they sort
    auto/<run>/jobs/                            sbatch files an attempt submitted, named after the attempt

Write GOAL.md, then `scripts/auto_start.sh <run>` submits a job that runs JupyterLab and Claude Code headless
on a GPU node (laptop can be closed). Progress: `auto/<run>/LOG.md`, transcript: `auto/<run>/claude-<jobid>.log`.
