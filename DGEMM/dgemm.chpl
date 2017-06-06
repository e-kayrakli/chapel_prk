use Time;
use BlockDist;
use RangeChunk;

config const order = 10,
             epsilon = 1e-8,
             iterations = 100,
             blockSize = 0,
             debug = false,
             validate = true;


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

        var AA: [blockDom] real,
            BB: [blockDom] real,
            CC: [blockDom] real;

        for niter in 0..#iterations {
          if tid==0 && (iterations==1 || niter==1) then t.start();

          for (jj,kk) in {myChunk by blockSize, vecRange by blockSize} {
            const jMax = min(jj+blockSize-1, myChunk.high);
            const kMax = min(kk+blockSize-1, vecRange.high);
            const jRange = 0..jMax-jj;
            const kRange = 0..kMax-kk;

            for (jB, j) in zip(jj..jMax, bVecRange) do
              for (kB, k) in zip(kk..kMax, bVecRange) do
                BB[j,k] = B[kB,jB];

            for ii in localDom.dim(1) by blockSize {
              const iMax = min(ii+blockSize-1, localDom.dim(1).high);
              const iRange = 0..iMax-ii;

              for (iB, i) in zip(ii..iMax, bVecRange) do
                for (kB, k) in zip(kk..kMax, bVecRange) do
                  AA[i,k] = A[iB, kB];

              local {
                for cc in CC do
                  cc = 0.0;

                for (k,j,i) in {kRange, jRange, iRange} do
                  CC[i,j] += AA[i,k] * BB[j,k];

                for (iB, i) in zip(ii..iMax, bVecRange) do
                  for (jB, j) in zip(jj..jMax, bVecRange) do
                    C[iB,jB] += CC[i,j];
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
