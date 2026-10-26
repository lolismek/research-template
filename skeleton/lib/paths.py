"""Where things live on the cluster. Import from here; never hard-code paths in notebooks."""
from pathlib import Path
import os, sys

SCRATCH = Path("/scratch/hewittlab/aij2115")
PROJECT = Path(os.environ.get("PROJECT_DIR", "{{CLUSTER_DIR}}"))
HF_CACHE = SCRATCH / "hf_cache"
RUNS = PROJECT / "runs"      # batch job outputs
DATA = PROJECT / "data"      # sidecar caches, data/<topic>/
LOGS = PROJECT / "logs"      # sidecar logs

os.environ.setdefault("HF_HOME", str(HF_CACHE))

# Extra packages not in the conda env, installed with `pip install --target` on scratch (home is over quota).
PYLIB = SCRATCH / "pylib"
if str(PYLIB) not in sys.path:
    sys.path.append(str(PYLIB))
