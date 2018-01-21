for sr in 10 05 01;
do
  echo $sr: $(grep Compressed out/aal_transpose_log_stat_$sr.out | cut -d: -f2 |  paste -s -d+ - | bc)
done

