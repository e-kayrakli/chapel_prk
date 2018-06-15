// This is forked from upstream repo in 
//    test/studies/prk
// Last sha was bd9303f6cd002f7070a450d94d3cbdc16b074b46
use Time;
use BlockDist;
use PrefetchPatterns;

param PRKVERSION = "2.17";

config param useBlockDist = true;

config const iterations = 100,
             order = 100,
             tileSize = 0,
             debug = false;

config param accessLogging = false;
config const commDiag = false;

config const handPrefetch = false; // to conform to the Makefile
config param lappsPrefetch = false;  // this needs to use correct chpl
config param autoPrefetch = false; // this needs to use correct chpl

//
// Process and test input configs
//
if iterations < 1 then
  halt("ERROR: iterations must be >= 1: ", iterations);

if order < 0 then
  halt("ERROR: Matrix Order must be greater than 0 : ", order);

if tileSize > order then
  halt("ERROR: Tile size cannot be larger than order");

// Determine tiling
const tiled = tileSize > 0;

// Domains
const localDom = {0..#order, 0..#order};
var tiledLocalDom = if tiled then
  {0..#order by tileSize, 0..#order by tileSize} else
  {0..5 by 1, 0..5 by 1}; //junk domain


const blockDist = new dmap(new Block(localDom));
const Dist =  if useBlockDist then blockDist
                              else defaultDist;

const Dom = localDom dmapped Dist;
const tiledDom = tiledLocalDom dmapped Dist;

var timer: Timer,
    bytes = 2.0 * numBytes(real) * order * order,
    A, B : [Dom] real;

//
// Print information before main loop
//
writeln("Parallel Research Kernels version ", PRKVERSION);
writeln("Serial Matrix transpose: B = A^T");
writeln("Max parallelism       = ", here.maxTaskPar);
writeln("Matrix order          = ", order);
if (tiled) then writeln("Tile size              = ", tileSize);
else            writeln("Untiled");
writeln("Number of iterations = ", iterations);

// Fill original column matrix
[(i, j) in Dom] A[i,j] = order*j + i;

// Initialize B for clarity
B = 0.0;

if accessLogging then
  A.enableAccessLogging("A");

//
// Main loop
//
if commDiag {
  startCommDiagnostics();
  startVerboseComm();
}
if lappsPrefetch then
  A._value.transposePrefetch();
if autoPrefetch then
  A._value.autoPrefetch();


for iteration in 0..iterations {
  // Start timer after a warmup lap
  if iteration == 1 then timer.start();

  if tiled {
    forall (i,j) in tiledDom {
      for it in i..#min(order-i, tileSize) {
        for jt in j..#min(order-j, tileSize) {
          B[it,jt] += A[jt,it];
        }
      }
    }
  }
  else {
    forall (i,j) in Dom {
      B[i,j] += A[j,i];
    }
  }
  forall a in A do
    a += 1.0;

} // end of main loop

timer.stop();

if commDiag {
  stopCommDiagnostics();
  stopVerboseComm();
  writeln(getCommDiagnosticsHere());
}

if accessLogging then
  B.finishAccessLogging();
//
// Analyze and output results
//

// Timings
const transposeTime = timer.elapsed(),
    avgTime = transposeTime / iterations;

// Verify correctness
const epsilon = 1.e-8;
const addit = ((iterations+1) * iterations)/2.0;
const absErr = + reduce [(i,j) in Dom]
    abs(B[i,j]-((order*i+j)*(iterations+1)+addit));

if absErr > epsilon then
  halt("ERROR: Aggregate squared error", absErr,
          " exceeds threshold ", epsilon);

// Report performance
writeln("Solution validates");
writeln("Rate (MB/s): ", 1.0E-06 * bytes / avgTime,
    " Avg time (s): ", avgTime);
