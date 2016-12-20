//
// Chapel's serial implementation of random
//
use Time;

extern proc sizeof(e): size_t;
param PRKVERSION = "2.15";

config param errorPercent = 1;

config const numTasks = here.maxTaskPar;
config const length : int = 4,
             update_ratio: int = 16,
             log2_table_size: int = 16,
             debug: bool = false,
             validate: bool = false,
             verbose = true;

param POLY:uint(64)=0x0000000000000007;
param PERIOD:int(64) = 1317624576693539401;
// sequence number in stream of random numbers to be used as initial value       
param SEQSEED:int(64) = 834568137686317453;

//
// Process and test input configs
//
if length < 0 then
  halt("ERROR: vector length must be >= 1: ", length);



// Domains

var timer: Timer;

var nstarts: int;                /* vector length                                */
var i, j, round, oldsize: int;   /* dummies                                      */
var err: int;                    /* number of incorrect table elements           */
var tablesize: int;              /* aggregate table size (all threads)           */
var nupdate: int;                /* number of updates per thread                 */
var tablespace: int;             /* bytes per thread required for table          */
var idx: int;                    /* idx into Table                               */
var random_time: real;           /* timer                                        */
var log2nstarts: int;            /* log2 of vector length                        */
var log2tablesize: int;          /* log2 of aggregate table size                 */
var log2update_ratio: int;       /* log2 of update ratio                         */


// initialization
nstarts = length;
log2nstarts = poweroftwo(nstarts);
log2update_ratio = poweroftwo(update_ratio);
tablesize = 2 ** log2_table_size;
tablespace = tablesize*8;
nupdate = update_ratio * tablesize;

//
// Print information before main loop
//
writeln("Parallel Research Kernels version ", PRKVERSION);
writeln("Chapel: Serial Random Access");
writeln("Table size (shared)    = ", tablesize);
writeln("Update ratio           = ", update_ratio);
writeln("Number of updates      = ", nupdate);
writeln("Vector length          = ", length);

const Dom = {0..#tablesize};
const DomA = {0..#nstarts};
var Table: [Dom] int;
var ran: [DomA] uint(64);

// Histograms for verbose mode
var hist: [Dom] uint;
var histHist: [Dom] int;


for i in 0.. # tablesize do Table[i] = i;

//
// Main loop
//
var v:  int;


timer.start();
// do two identical rounds of Random Access to make sure we recover the
// initial condition
coforall t in 0..#here.maxTaskPar {
  const offset = t*nstarts;
  var idx: int;
  for round in 0..#2 {

    for j in 0..#nstarts do
      ran[j] = PRK_starts(SEQSEED+(nupdate/nstarts)*(j+offset));

    for j in 0..#nstarts {
      //because we do two rounds, we divide nupdates in two
      for i in 0.. #nupdate/(nstarts*2) {
        ran[j] = (ran[j] << 1) ^ if ran[j]:int(64)<0 then POLY
          else 0;
        idx = (ran[j] & (tablesize-1)):int;
        Table[idx] ^= (ran[j]):int;
        if verbose then
          hist[idx] += 1;
      }
    }
  }
}

// Timings
timer.stop();
random_time = timer.elapsed();

/* verification test */
for i in DomA {
  if Table[i] != i:uint(64) {
    writeln ("Error Table[",i,"]=",Table[i]);
    err +=1;
  }
}

// output
if (err>0 && errorPercent==0 ||
    err/tablesize > errorPercent*0.01) {
  writeln("ERROR: number of incorrect table elements: ",err);
  }
else {
  writeln("Solution validates, number of errors: ",err);
  writeln("Rate (GUPs/s): ", 1.0E-9*nupdate/random_time,", time (s) = ",random_time);
}

//print out histogram
if verbose {
  writeln("HistHist: ");
  for i in Dom do histHist[hist[i]:int] += 1;
  for i in Dom {
    if histHist[i] != 0 {
      writeln("histhist[", i, "] = ", histHist[i]);
    }
  }
}

/* Utility routine to start random number generator at nth step*/

// I am keeping argument and return types as this function involves a
// lot of bit arithmetic. Engin
proc PRK_starts(m:int(64)):uint(64) {
  var i, j, n:  int;
  var m2: [64] uint;
  var temp, ran: uint(64);

  n = m;

  while n<0 do
    n += PERIOD;

  while n > PERIOD do;
  n -= PERIOD;

  if n == 0 then return 0x1;

  temp = 0x1;
  for i in 0.. #64 {
    m2[i] = temp;
    temp = (temp << 1) ^ if temp:int(64)<0 then POLY else 0;
    temp = (temp << 1) ^ if temp:int(64)<0 then POLY else 0;
  }

  for ii in 0..62 by -1 {
    if ((n >> i) & 1) {
      i = ii;
      break;
    }
  }

  ran = 0x2;
  while i > 0 {
    temp = 0;
    for j in 0.. # 64 {
      if (((ran >> j) & 1):uint(64))
                           then temp ^= m2[j];
    }
    ran = temp;
    i -= 1;
    if ((n >> i) & 1) then
      ran = (ran << 1) ^ if ran:int(64)<0 then POLY else 0 ;
  }
  return ran;
}

/* utility routine that tests whether an integer is a power of two         */
proc poweroftwo(n) {
  var log2n: int;
  var t: int;

  log2n = n;
  t=0;

  do {
    t +=1;
    log2n = log2n >> 1 ;
  } while (log2n > 0);

  return (t-1);
}
