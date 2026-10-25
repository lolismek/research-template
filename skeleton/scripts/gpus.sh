#!/usr/bin/env bash
# Show my GPU usage against the cap before submitting anything.
CAP=4
echo "== my jobs =="
squeue -u "$USER" -o "%.9i %.12j %.2t %.10M %.6b %R"
n=$(squeue -u "$USER" -h -o "%b" | grep -o 'gpu:[0-9]*' | awk -F: '{s+=$2} END{print s+0}')
echo "== GPUs held: $n / $CAP =="
echo "== nodes =="
sinfo -p hewittlab -o "%N %G %T %C" -h
