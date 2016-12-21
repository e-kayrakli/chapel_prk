use Time;

config const order = 10,
             epsilon = 1e-8,
             iterations = 100,
             blockSize = 0,
             debug = false,
             validate = true;


// TODO current logic assumes order is divisible by blockSize. add that
// check

const vecRange = 0..#order;

const matrixDom = {vecRange, vecRange};
var A: [matrixDom] real,
    B: [matrixDom] real,
    C: [matrixDom] real;

forall (i,j) in matrixDom {
  A[i,j] = j;
  B[i,j] = j;
  C[i,j] = 0;
}


const refChecksum = (iterations) *
    (0.25*order*order*order*(order-1.0)*(order-1.0));

const t = new Timer();

if blockSize == 0 {
  for niter in 0..#iterations {
    if iterations==1 || niter==1 then t.start();

    //TODO OpenMP version uses jik loops and parallelizes j loop, I
    //haven't seen any benefit of my laptop in Chapel, but it requires
    //further study. Engin
    forall (i,j,k) in {vecRange, vecRange, vecRange} {
      C[i,j] += A[i,k] * B[k,j];
    }
  }
  t.stop();
}
else {
  // variables for blocked dgemm
  const bVecRange = 0..#blockSize;
  const blockDom = {bVecRange, bVecRange};

  // we need task-local arrays for blocked matrix multiplication. It
  // seems that in intent for arrays is not working currently, so I am
  // falling back to writing my own coforall. Engin
  coforall tid in 0..#here.maxTaskPar {

    const numElems = order/blockSize;
    const myChunk = _computeBlock(numElems, here.maxTaskPar, tid,
        numElems-1, 0, 0);

    var AA: [blockDom] real,
        BB: [blockDom] real,
        CC: [blockDom] real;

    const iterDomain = {bVecRange, bVecRange, bVecRange};

    for niter in 0..#iterations {
      if tid==0 && (iterations==1 || niter==1) then t.start();

      for (jjj,kk) in {myChunk[1]..myChunk[2], vecRange by blockSize} {
        const jj = jjj*blockSize;

        for (jB, j) in zip(jj..#blockSize, bVecRange) do
          for (kB, k) in zip(kk..#blockSize, bVecRange) do
            BB[j,k] = B[kB,jB];

        for ii in vecRange by blockSize {
          /*AA = A[ii..#blockSize, kk..#blockSize];*/
          for (iB, i) in zip(ii..#blockSize, bVecRange) do
            for (kB, k) in zip(kk..#blockSize, bVecRange) do
              AA[i,k] = A[iB, kB];

          for cc in CC do cc = 0.0;

          for (i,j,k) in iterDomain do
            CC[i,j] += AA[i,k] * BB[j,k];

          for (iB, i) in zip(ii..#blockSize, bVecRange) do
            for (jB, j) in zip(jj..#blockSize, bVecRange) do
              C[iB,jB] += CC[i,j];
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
