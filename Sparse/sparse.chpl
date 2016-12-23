use Time;
use LayoutCSR;

config param directAccess = false;

config const lsize = 5;
config const radius = 2;
const stencilSize = 4*radius+1;
config const iterations = 10;
config const debug = false;


const lsize2 = 2*lsize;
const size = 1<<lsize;
const size2 = size*size;
/*const size2 = 2**(2*lsize);*/

const parentDom = {0..#size2, 0..#size2};
var matrixDom: sparse subdomain(parentDom) dmapped CSR();

//initialize sparse domain
for row in 0..#size2 {
  const i = row%size;
  const j = row/size;

  matrixDom += (row, LIN(i,j));
  for r in 1..radius {
    matrixDom += (row, LIN((i+r)%size,j));
    matrixDom += (row, LIN((i-r+size)%size,j));
    matrixDom += (row, LIN(i, (j+r)%size));
    matrixDom += (row, LIN(i, (j-r+size)%size));
  }
}

var matrix: [matrixDom] real;

forall (i,j) in matrixDom do
  matrix[i,j] = 1.0/(j+1);

const vectorDom = {0..#size2};
var vector: [vectorDom] real;
var result: [vectorDom] real;
vector = 0;
result = 0;

if debug {
  writeln("Matrix: ");
  for i in parentDom.dim(1) {
    for j in parentDom.dim(2) {
      writef("%.2r ", matrix[i,j]);
    }
    writeln();
  }

  writeln();
  writeln("Vector");
  for v in vector do write(v, " ");
  writeln();
}

const t = new Timer();
for niter in 0..iterations {

  if niter == 1 then t.start();
  forall i in vectorDom do
    vector[i] += i+1;

  // do the multiplication
  if !directAccess {
    forall (i,j) in matrixDom {
      result[i] += matrix[i,j] * vector[j];
    }
  }
  else {
    const ref sparseDom = matrixDom._instance;
    const ref sparseArr = matrix._instance;

    forall i in parentDom.dim(1) {
      for j in sparseDom.rowStart[i]..sparseDom.rowStop[i]{
        result[i] += sparseArr.data[j] * vector[sparseDom.colIdx[j]];
      }
    }
  }
}
t.stop();

// verify the result
const epsilon = 1e-8;
const referenceSum = 0.5 * matrixDom.numIndices * (iterations+1) *
    (iterations+2);
const vectorSum = + reduce result;
if abs(vectorSum-referenceSum) > epsilon then
  halt("Validation failed. Reference sum = ", referenceSum,
      " Vector sum = ", vectorSum);

writeln("Validation successful");
const nflop = 2.0*matrixDom.numIndices;
const avgTime = t.elapsed()/iterations;
writeln("Rate (MFlops/s): ", 1e-6*nflop/avgTime, " Avg time (s): ",
    avgTime);

inline proc LIN(i, j) {
  return (i+(j<<lsize));
}

