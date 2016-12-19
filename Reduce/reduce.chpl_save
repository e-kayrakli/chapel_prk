//
// Chapel's serial implementation of reduce
//
use Time;

param PRKVERSION = "2.15";

config const numTasks = here.maxTaskPar;
config const iterations : int = 100,
             length : int = 100,
             debug: bool = false,
             validate: bool = false;

config var tileSize: int = 0;

//
// Process and test input configs
//
if (iterations < 1) {
  writeln("ERROR: iterations must be >= 1: ", iterations);
  exit(1);
}
if (length < 0) {
  writeln("ERROR: vector length must be >= 1: ", length);
  exit(1);
}

// Domains
const    Dom = {0.. # length};

var timer: Timer,
    vector, vector2, ones, ones2 : [Dom] real;

//
// Print information before main loop
//
if (!validate) {
  writeln("Parallel Research Kernels version ", PRKVERSION);
  writeln("Chapel: Serial Vector Reduction");
  writeln("Vector length          = ", length);
  writeln("Number of iterations   = ", iterations);
}

// initialize the arrays      
vector  = 1;
vector2 = 1;
ones    = 1;
ones2   = 1;

//
// Main loop
//
for iteration in 0.. iterations {
  // Start timer after a warmup lap
  if (iteration == 1) then timer.start();

//coforall tid in 0..#numTasks do
  //for i in 0.. # length {
  forall (i) in Dom {
    vector[i] += ones[i];
  }
    //vector += ones;

} // end of main loop

// Timings
var reduceTime = timer.elapsed(),
    avgTime = reduceTime / iterations;

timer.stop();
for iteration in 0.. iterations {
  // Start timer after a warmup lap
  if (iteration == 1) then timer.start();
    vector2 += ones2;
}
var reduceTime2 = timer.elapsed(),
    avgTime2 = reduceTime2 / iterations;

//
// Analyze and output results
//


// Error tolerance
const epsilon = 1.e-8;

// verify correctness */
var element_value = iterations + 2.0;
 
var absErr = 0.0;
for i in 0.. #length {
  if (abs(vector[i] - element_value) >= epsilon) {
     writeln("First error at i=",i,"; value: ",vector[i],"; reference value: ",element_value); 
     }
}


// Verify correctness
if (absErr < epsilon) {
  writeln("Solution validates");
  writeln("Rate (MFlops/s): ", 1.0E-06 * (2.0-1.0)*length/avgTime," Avg time (s): ",avgTime);
  writeln("Rate2 (MFlops/s): ", 1.0E-06 * (2.0-1.0)*length/avgTime2," Avg time (s): ",avgTime2);
}


