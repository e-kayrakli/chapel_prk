use Barrier;
use Time;
use BlockDist;
use RangeChunk;
use commMethods;

config const order = 10,
             epsilon = 1e-8,
             iterations = 100,
             blockSize = 0,
             debug = false,
             validate = true;

config const staticDomain = false;

config param  prefetch = false,
             consistent = true;


// TODO current logic assumes order is divisible by blockSize. add that
// check

const vecRange = 0..#order;

const matrixSpace = {vecRange, vecRange};
const matrixDom = matrixSpace dmapped Block(matrixSpace);
var A: [matrixDom] real,
    B: [matrixDom] real,
    C: [matrixDom] real;

forall (i,j) in matrixDom {
  A[i,j] = j;
  B[i,j] = j;
  C[i,j] = 0;
}

const nTasksPerLocale = here.maxTaskPar;
writeln("Chapel Dense matrix-matrix multiplication");
writeln("Max parallelism      =   ", nTasksPerLocale);
writeln("Matrix order         =   ", order);
writeln("Blocking factor      =   ", if blockSize>0 then blockSize+""
    else "N/A");
writeln("Number of iterations =   ", iterations);
writeln();

const refChecksum = (iterations) *
    (0.25*order*order*order*(order-1.0)*(order-1.0));

if prefetch {
  A._instance.rowWiseAllGather(consistent, staticDomain);
  B._instance.colWiseAllGather(consistent, staticDomain);
}

var t = new Timer();

if blockSize == 0 {
  for niter in 0..#iterations {
    if iterations==1 || niter==1 then t.start();

    //TODO OpenMP version uses jik loops and parallelizes j loop, I
    //haven't seen any benefit of my laptop in Chapel, but it requires
    //further study. Engin
    forall (j,k,i) in {vecRange, vecRange, vecRange} {
      C[i,j] += A[i,k] * B[k,j];
    }
  }
  t.stop();
}
else {
  // we need a barrier to artificially create some communicaiton in each
  // iteration. Note that this is not really necessary for dgemm to run
  // correctly and validate
  var b = new Barrier(numLocales*nTasksPerLocale);

  // we need task-local arrays for blocked matrix multiplication. It
  // seems that in intent for arrays is not working currently, so I am
  // falling back to writing my own coforall. Engin
  coforall l in Locales with (ref t) {
    on l {
      const bVecRange = 0..#blockSize;
      const blockDom = {bVecRange, bVecRange};
      const localDom = matrixDom.localSubdomain();

      coforall tid in 0..#nTasksPerLocale with (ref t) {
        const myChunk = chunk(localDom.dim(2), nTasksPerLocale, tid);
        const tileIterDom =
          {myChunk by blockSize, vecRange by blockSize};

        var AA = c_calloc(real, blockDom.size);
        var BB = c_calloc(real, blockDom.size);
        var CC = c_calloc(real, blockDom.size);
        for niter in 0..#iterations {

          b.barrier();
          if l.id==0 && tid==0 {
            if !consistent {
              A._value.updatePrefetch();
              B._value.updatePrefetch();
            }
          }

          if l.id==0 && tid==0 && (iterations==1 || niter==1) then t.start();

          for (jj,kk) in tileIterDom {
            // two parts are identical
            if prefetch && !consistent {
              local { //comment this if !prefetch
                const jMax = min(jj+blockSize-1, myChunk.high);
                const kMax = min(kk+blockSize-1, vecRange.high);
                const jRange = 0..jMax-jj;
                const kRange = 0..kMax-kk;

                for (jB, j) in zip(jj..jMax, bVecRange) do
                  for (kB, k) in zip(kk..kMax, bVecRange) do
                    BB[j*blockSize+k] = B[kB,jB];

                for ii in localDom.dim(1) by blockSize {
                  const iMax = min(ii+blockSize-1, localDom.dim(1).high);
                  const iRange = 0..iMax-ii;

                  for (iB, i) in zip(ii..iMax, bVecRange) do
                    for (kB, k) in zip(kk..kMax, bVecRange) do
                      AA[i*blockSize+k] = A[iB, kB];

                  local {
                    c_memset(CC, 0:int(32), blockDom.size*8);

                    // we could create domains here, but domain literals
                    // trigger fences. So iterate over ranges
                    // explicitly.
                    for k in kRange {
                      for j in jRange {
                        for i in iRange {
                          CC[i*blockSize+j] += AA[i*blockSize+k] *
                            BB[j*blockSize+k];
                        }
                      }
                    }

                    for (iB, i) in zip(ii..iMax, bVecRange) do
                      for (jB, j) in zip(jj..jMax, bVecRange) do
                        C[iB,jB] += CC[i*blockSize+j];
                  }
                }
              }
            }
            else {
              const jMax = min(jj+blockSize-1, myChunk.high);
              const kMax = min(kk+blockSize-1, vecRange.high);
              const jRange = 0..jMax-jj;
              const kRange = 0..kMax-kk;

              for (jB, j) in zip(jj..jMax, bVecRange) do
                for (kB, k) in zip(kk..kMax, bVecRange) do
                  BB[j*blockSize+k] = B[kB,jB];

              for ii in localDom.dim(1) by blockSize {
                const iMax = min(ii+blockSize-1, localDom.dim(1).high);
                const iRange = 0..iMax-ii;

                for (iB, i) in zip(ii..iMax, bVecRange) do
                  for (kB, k) in zip(kk..kMax, bVecRange) do
                    AA[i*blockSize+k] = A[iB, kB];

                local {
                  c_memset(CC, 0:int(32), blockDom.size*8);

                  // we could create domains here, but domain literals
                  // trigger fences. So iterate over ranges
                  // explicitly.
                  for k in kRange {
                    for j in jRange {
                      for i in iRange {
                        CC[i*blockSize+j] += AA[i*blockSize+k] *
                          BB[j*blockSize+k];
                      }
                    }
                  }

                  for (iB, i) in zip(ii..iMax, bVecRange) do
                    for (jB, j) in zip(jj..jMax, bVecRange) do
                      C[iB,jB] += CC[i*blockSize+j];
                }
              }
            }
          }
        }
      }
    }
  }
  t.stop();
}

if validate {
  const checksum = + reduce C;
  if abs(checksum-refChecksum)/refChecksum > epsilon then
    halt("VALIDATION FAILED!\n \
        Reference checksum = ", refChecksum, " Checksum = ",
        checksum);
}

const nflops = 2.0*(order**3);
const avgTime = t.elapsed()/iterations;
writeln("Validation succesful.");
writeln("Rate(MFlop/s) = ", 1e-6*nflops/avgTime, " Time : ", avgTime);

inline proc c_memset(dest :c_ptr, val: int(32), n: integral) {
  extern proc memset(dest: c_void_ptr, val: c_int, n: size_t):
    c_void_ptr;
  return memset(dest, val, n.safeCast(size_t));
}
