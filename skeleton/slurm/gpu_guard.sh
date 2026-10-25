# Source at the start of a job. If the GPU Slurm gave us is already in use by a process that is
# not ours (this cluster does not always keep other users off allocated cards), resubmit this
# job with the current node excluded and exit.
#
# Occupied card: hold this (unusable) allocation for a while so Slurm does not hand us the same
# card straight back, then resubmit with the same exclusions. Faulty card (CUDA health check
# fails, e.g. uncorrectable ECC): resubmit with this node added to the exclusions.
# Memory in use on our card via the CUDA runtime (nvidia-smi/NVML is broken on some nodes, e.g. a
# driver/library mismatch on csrtx6000-1 while CUDA itself works). Empty if CUDA fails -> health check below.
used=$(~/miniforge3/envs/{{CONDA_ENV}}/bin/python -c "import torch; f,t=torch.cuda.mem_get_info(); print((t-f)//2**20)" 2>/dev/null)
if [ "${used:-0}" -gt 2000 ]; then
  echo "GPU on $(hostname) already has ${used} MiB in use by a foreign process; waiting 10 min then resubmitting${EXCLUDE:+ with --exclude=$EXCLUDE}"
  sleep 600
  sbatch ${EXCLUDE:+--exclude="$EXCLUDE"} --export=ALL,EXCLUDE="$EXCLUDE" "$0"
  exit 0
fi
if ! ~/miniforge3/envs/{{CONDA_ENV}}/bin/python -c "import torch; (torch.ones(1024,1024,device='cuda')@torch.ones(1024,1024,device='cuda')).sum().item()" >/dev/null 2>&1; then
  EXC="${SLURM_JOB_NODELIST}${EXCLUDE:+,$EXCLUDE}"
  echo "GPU on $(hostname) fails a CUDA health check (e.g. uncorrectable ECC error); resubmitting with --exclude=$EXC"
  sbatch --exclude="$EXC" --export=ALL,EXCLUDE="$EXC" "$0"
  exit 0
fi
echo "GPU on $(hostname) healthy and free (${used} MiB used)"
