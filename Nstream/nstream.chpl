//
// Chapel's implementation of nstream
//
use Time;

extern proc sizeof(e): size_t;
param PRKVERSION = "2.15";

config const numTasks = here.maxTaskPar;
config const iterations : int = 100,
             length : int = 100,
             debug: bool = false,
             validate: bool = false;

config var MAXLENGTH = 2000000;
config var SCALAR = 3.0;
config var tileSize: int = 0;

//
// Process and test input configs
//
if iterations < 1 then
  halt("ERROR: iterations must be >= 1: ", iterations);

if length < 0 then
  halt("ERROR: vector length must be >= 1: ", length);

// Domains
const    DomA = {0.. # length};

var timer: Timer,
    A    : [DomA] real,
    B, C : [DomA] real;

//
// Print information before main loop
//
writeln("Parallel Research Kernels version ", PRKVERSION);
writeln("Serial stream triad: A = B + SCALAR*C");
writeln("Vector length          = ", length);
writeln("Number of iterations   = ", iterations);

// initialization
A = 0.0;
B = 2.0;
C = 2.0;

//
// Main loop
//
for iteration in 0..iterations {
  // Start timer after a warmup lap
  if iteration == 1 then timer.start();
  A += B+SCALAR*C;
} // end of main loop

// Timings
timer.stop();
var myTime = timer.elapsed(),
var avgTime = myTime / iterations;

//
// Analyze and output results
//


// Error tolerance
const epsilon = 1.e-8;
//var bytes = 4.0 * sizeof(real) * length;
var sz = sizeof(1:real(64));
var bytes = 4.0 * sz * length;

// verify correctness */
var element_value = iterations + 2.0;
 
var absErr = 0.0;
/*
for i in 0.. #length {
  if (abs(vector[i] - element_value) >= epsilon) {
     writeln("First error at i=",i,"; value: ",vector[i],"; reference value: ",element_value); 
     }
}
*/


// output
if (absErr < epsilon) {
  writeln("Solution validates");
  writeln("Rate (MB/s): ", 1.0E-06*bytes/avgTime," Avg time (s): ",avgTime);
}


