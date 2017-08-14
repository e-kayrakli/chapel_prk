#!/bin/sh

hosts=( pyramid george )

for h in "${hosts[@]}"
do
  echo Host: $h
  make cleanout
  cd out
  tar xzvf datapack_*_$h\_4096_1.tar.gz
  cd ..
  python scripts/run.py --slurm PLOT 4096 1
  cp radius_analysis.png ~/papers/prefetch_v3/plots_new/synth/radius_analysis_$h.png
done
