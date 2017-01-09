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

writeln("Chapel Dense matrix-matrix multiplication");
writeln("Max parallelism      =   ", here.maxTaskPar);
writeln("Matrix order         =   ", order);
writeln("Blocking factor      =   ", if blockSize>0 then blockSize+""
    else "N/A");
writeln("Number of iterations =   ", iterations);
writeln();

const refChecksum = (iterations) *
    (0.25*order*order*order*(order-1.0)*(order-1.0));

const t = new Timer();

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

    /*var AA: [blockDom] real,*/
        /*BB: [blockDom] real,*/
        /*CC: [blockDom] real;*/

    var AA = c_calloc(real, blockDom.size);
    var BB = c_calloc(real, blockDom.size);
    var CC = c_calloc(real, blockDom.size);

    const iterDomain = {bVecRange, bVecRange, bVecRange};

    for niter in 0..#iterations {
      if tid==0 && (iterations==1 || niter==1) then t.start();

      for (jjj,kk) in {myChunk[1]..myChunk[2], vecRange by blockSize} {
        const jj = jjj*blockSize;

        for (jB, j) in zip(jj..#blockSize, bVecRange) do
          for (kB, k) in zip(kk..#blockSize, bVecRange) do
            /*BB[j,k] = B[kB,jB];*/
            BB[j*blockSize+k] = B[kB,jB];

        for ii in vecRange by blockSize {
          /*AA = A[ii..#blockSize, kk..#blockSize];*/
          for (iB, i) in zip(ii..#blockSize, bVecRange) do
            for (kB, k) in zip(kk..#blockSize, bVecRange) do
              /*AA[i,k] = A[iB, kB];*/
              AA[i*blockSize+k] = A[iB, kB];

          c_memset(CC, 0:int(32), blockDom.size*8);

          for (k,j,i) in iterDomain do
            /*CC[i,j] += AA[i,k] * BB[j,k];*/
            CC[i*blockSize+j] += AA[i*blockSize+k] * BB[j*blockSize+k];

          for (iB, i) in zip(ii..#blockSize, bVecRange) do
            for (jB, j) in zip(jj..#blockSize, bVecRange) do
              /*C[iB,jB] += CC[i,j];*/
              C[iB,jB] += CC[i*blockSize+j];
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
