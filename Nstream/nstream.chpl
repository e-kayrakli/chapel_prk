//
// Chapel's implementation of nstream
//
use Time;

param PRKVERSION = "2.15";

config param lowLevel = false;
config const iterations : int = 100,
             length : int = 100,
             validate: bool = false;

config var SCALAR = 3.0;

//
// Process and test input configs
//
if iterations < 1 then
  halt("ERROR: iterations must be >= 1: ", iterations);

if length < 0 then
  halt("ERROR: vector length must be >= 1: ", length);

// Domains
const    Dom = {0.. # length};

var A    : [Dom] real,
    B, C : [Dom] real;

//
// Print information before main loop
//
writeln("Parallel Research Kernels version ", PRKVERSION);
writeln("Serial stream triad: A = B + SCALAR*C");
writeln("Max parallelism        = ", here.maxTaskPar);
writeln("Vector length          = ", length);
writeln("Number of iterations   = ", iterations);

// initialization
A = 0.0;
B = 2.0;
C = 2.0;

const timer = new Timer();
if lowLevel {
  coforall tid in 0..#here.maxTaskPar {

    const numElems = length/here.maxTaskPar;
    const myChunk = _computeBlock(length, here.maxTaskPar, tid,
        length-1, 0, 0);
    const myRange = myChunk[1]..myChunk[2];

    //
    // Main loop
    //
    for iteration in 0..iterations {
      if tid == 0 && iteration == 1 then
        timer.start(); //Start timer after a warmup lap

      for i in myRange do
        A[i] += B[i]+SCALAR*C[i];
    }
  }
}
else {
  for iteration in 0..iterations {
    if iteration == 1 then
      timer.start(); //Start timer after a warmup lap

    A += B+SCALAR*C;
  }
}

// Timings
timer.stop();
var avgTime = timer.elapsed() / iterations;
timer.clear();

//
// Analyze and output results
//
if validate {
  config const epsilon = 1.e-8;

  var aj=0.0, bj=2.0, cj=2.0;
  for 0..iterations do
    aj += bj+SCALAR*cj;

  aj = aj * length:real;

  var asum = 0.0;
  for j in Dom do asum += A[j]; //reduce sequentially

  if abs(aj-asum)/asum <= epsilon then
    writeln("Validation successful");
  else
    halt("Validation failed");
}

const bytes = 4 * 8 * length;
writeln("Rate (MB/s): ", 1.0E-06*bytes/avgTime,
   " Avg time (s): ",avgTime);



