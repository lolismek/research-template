Autoresearch runs, one folder per goal:

    auto/<run>/GOAL.md                          question, bar for success, what is off limits
    auto/<run>/LOG.md                           one short entry per attempt, pointing to its notebook
    auto/<run>/notebooks/NN_YYYY-MM-DD_label.ipynb   one per attempt, numbered so they sort
    auto/<run>/jobs/                            sbatch files an attempt submitted, named after the attempt

Each run uses its own notebook job (`scripts/nb_start.sh --name <run>`), never the user's kernel.
