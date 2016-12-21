use Time;

config const order = 10,
             epsilon = 1e-8,
             iterations = 100;

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

const checksum = + reduce C;
if abs(checksum-refChecksum)/refChecksum > epsilon {
  writeln("Reference checksum = ", refChecksum, " Checksum = ",
      checksum);
  halt("Checksum failed");
}

const nflops = 2.0*(order**3);
const avgTime = t.elapsed()/iterations;

writeln("Rate(MFlop/s) = ", 1e-6*nflops/avgTime, " Time : ", avgTime);


