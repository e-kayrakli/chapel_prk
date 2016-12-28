num_threads=(01 02)
niter=1000
execname=dgemm

order=$1
block_size=(00 32 64)

make cleanout
for b in "${block_size[@]}"; do
  execflags="--order=$order --blockSize=$block_size"
  for t in "${num_threads[@]}"; do
    echo "Running $execname > THREADS=$t BLOCK SIZE=$b"
    CHPL_RT_NUM_THREADS_PER_LOCALE=$t ./$execname --iterations=$niter\
                                                  $execflags\
                                                  >./out/$execname.$t.$b
  done
done

# parse results
for b in "${block_size[@]}"; do
  echo "Parsing $execname > BLOCK SIZE=$b"
  grep -Ri rate out/*$b* | sort -n | cut -d" " -f3\
                                      >out/$execname.$b.perf
  cat out/$execname.$b.perf
done
