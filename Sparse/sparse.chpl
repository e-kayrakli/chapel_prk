use BlockDist;
use Time;
use LayoutCSR;
use PrefetchPatterns;

param PRKVERSION = "2.17";

config param useBlockDist = true; //just to keep the build system happy
config param rowDistributeMatrix = true;

// for bulkAdd improvement purposes - can be removed
config const timeBulkAdd = false;
config const order = 5, //formerly known as lsize
             radius = 2,
             iterations = 10,
             scramble = true;

// const for now TODO make param after correctness tests
config param handPrefetch = false;
config const prefetch = false,
             consistent = true;
config const staticDomain = false;

config const distSpsDomInit = true;

const lsize2 = 2*order;
const size = 1<<order;
const size2 = size*size;
const stencilSize = 4*radius+1;
const sparsity = stencilSize:real/size2;

// create vector domain
const vectorSpace = {0..#size2};
var vectorDom = vectorSpace dmapped Block(vectorSpace);

// create matrix domain
var rowDistLocDom = {0..#numLocales, 0..0};
var rowDistLocArr: [rowDistLocDom] locale;
rowDistLocArr[0..#numLocales, 0] = Locales[0..#numLocales];

const parentDom = {0..#size2, 0..#size2};
var matrixDenseDom = parentDom dmapped Block(parentDom,
            targetLocales=if rowDistributeMatrix then
              rowDistLocArr else Locales,
            sparseLayoutType=CSR);

var matrixDom: sparse subdomain(matrixDenseDom);

//initialize sparse domain
if !distSpsDomInit || numLocales==1 || !rowDistributeMatrix { // naive ind addition

  // temporary index buffer for fast initialization
  const indBufDom = {0..#(size2*stencilSize)};
  var indBuf: [indBufDom] 2*int;

  for row in 0..#size2 {
    const i = row%size;
    const j = row/size;

    var bufIdx = row*stencilSize;

    indBuf[bufIdx] = (row, reverse(LIN(i,j)));
    for r in 1..radius {
      indBuf[bufIdx+1] = (row, reverse(LIN((i+r)%size,j)));
      indBuf[bufIdx+2] = (row, reverse(LIN((i-r+size)%size,j)));
      indBuf[bufIdx+3] = (row, reverse(LIN(i, (j+r)%size)));
      indBuf[bufIdx+4] = (row, reverse(LIN(i, (j-r+size)%size)));
      bufIdx += 4;
    }
  }
  var initTimer = new Timer();
  if timeBulkAdd {
    initTimer.start();
  }
  matrixDom.bulkAdd(indBuf, preserveInds=false);
  if timeBulkAdd {
    initTimer.stop();
    writeln("Initialization time : ", initTimer.elapsed());
  }
}
else { // create indices in distributed fashion
  var rowDistDom = vectorSpace dmapped Block(vectorSpace);

  var addingToNNZ$: sync bool;

  coforall l in Locales do on l {

    // temporary index buffer for fast initialization

    const locRowDistDom = rowDistDom.localSubdomain();
    const numLocInds = stencilSize*locRowDistDom.numIndices;
    const indBufDom = {0..#numLocInds};
    var indBuf: [indBufDom] 2*int;

    // TODO this is very similar to what we have above -- refactor it
    for row in locRowDistDom {
      const i = row%size;
      const j = row/size;

      var bufIdx = (row-locRowDistDom.low)*stencilSize;

      indBuf[bufIdx] = (row, reverse(LIN(i,j)));
      for r in 1..radius {
        indBuf[bufIdx+1] = (row, reverse(LIN((i+r)%size,j)));
        indBuf[bufIdx+2] = (row, reverse(LIN((i-r+size)%size,j)));
        indBuf[bufIdx+3] = (row, reverse(LIN(i, (j+r)%size)));
        indBuf[bufIdx+4] = (row, reverse(LIN(i, (j-r+size)%size)));
        bufIdx += 4;
      }
    }
    // this assumes that targetLocales is all the locales in the same
    // order as in Locales
    const indsAdded =
      matrixDom._value.locDoms[(l.id,0)].mySparseBlock.bulkAdd(indBuf,
        preserveInds=false);

  }
  matrixDom._value.nnz = size2*stencilSize;
}


//do a sanitiy check to make sure we have created correct numver of
//indicese in the sparse domain
if matrixDom.numIndices != size2*stencilSize then
  halt("Incorrect number of indices created");

var matrix: [matrixDom] real;
[(i,j) in matrixDom] matrix[i,j] = 1.0/(j+1);

var vector: [vectorDom] real;
var result: [vectorDom] real;
vector = 0;
result = 0;

// Print information before main loop
writeln("Parallel Research Kernels Version ", PRKVERSION);
writeln("Sparse matrix-dense vector multiplication");
writeln("Max parallelism      = ", here.maxTaskPar);
writeln("Row distribution     = ", rowDistributeMatrix);
writeln("Matrix order         = ", size2);
writeln("Stencil diameter     = ", 2*radius+1);
writeln("Sparsity             = ", sparsity);
writeln("Number of iterations = ", iterations);
writeln("Indexes are ", if !scramble then "not " else "", "scrambled");

if prefetch {
  if !rowDistributeMatrix {
    matrix._value.rowWiseAllGather(consistent=consistent,
        staticDomain=staticDomain);
  }
  vector._value.allGather(consistent=consistent,
      staticDomain=staticDomain);
}

var t = new Timer();
for niter in 0..iterations {

  if niter == 1 then t.start();
  [i in vectorDom] vector[i] += i+1;

  if !handPrefetch {
    if !consistent then vector._value.updatePrefetch();
    // no privatization in sparse domains -> no local statement :(
    forall i in vectorDom {
      // the following call to dimiter should'nt be too horrible if
      // rowDistributeMatrix==true
      for j in matrixDom.dimIter(2, i) {
        result[i] += matrix[i,j] * vector[j];
      }
    }
  }
  else {
    coforall l in Locales do on l {
      const localSubDom = vectorDom.localSubdomain();

      var localVector: [vectorSpace] real;
      localVector = vector;
      forall i in localSubDom {
        for j in matrixDom.dimIter(2, i) {
          var tmp: real;
          local {
            tmp = localVector[j];
          }
          result[i] += matrix[i,j] * tmp;
        }
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
writeln("Rate (MFlops/s): ", 1e-6*nflop/avgTime, " Average (s): ",
    avgTime);

inline proc LIN(i, j) {
  return (i+(j<<order));
}

proc reverse(xx) {
  if !scramble then return xx;

  var x = xx:uint;

  x = ((x >> 1)  & 0x5555555555555555) | ((x << 1)  & 0xaaaaaaaaaaaaaaaa);
  x = ((x >> 2)  & 0x3333333333333333) | ((x << 2)  & 0xcccccccccccccccc);
  x = ((x >> 4)  & 0x0f0f0f0f0f0f0f0f) | ((x << 4)  & 0xf0f0f0f0f0f0f0f0);
  x = ((x >> 8)  & 0x00ff00ff00ff00ff) | ((x << 8)  & 0xff00ff00ff00ff00);
  x = ((x >> 16) & 0x0000ffff0000ffff) | ((x << 16) & 0xffff0000ffff0000);
  x = ((x >> 32) & 0x00000000ffffffff) | ((x << 32) & 0xffffffff00000000);
  return (x>>(64-lsize2)):int;
}

// TODO add prefetch checks for fast iteration
// TODO contribute this back
iter SparseBlockDom.dimIter(param dim, idx) {
  var targetLocRow = dist.targetLocsIdx((idx, whole.dim(2).low));
  /*writeln("dimIter idx: ", idx, " targetLocRow ", targetLocRow);*/

  for l in dist.targetLocales.domain.dim(2) {
    for idx in locDoms[(targetLocRow[1], l)].mySparseBlock.dimIter(2, idx) {
      yield idx;
    }
  }
}
