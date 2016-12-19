//
// Chapel's serial implementation of random
//
use Time;

extern proc sizeof(e): size_t;
param PRKVERSION = "2.15";

config const numTasks = here.maxTaskPar;
config const iterations : int = 100,
             length : int = 4,
             update_ratio: int = 16,
             log2_table_size: int = 16,
             debug: bool = false,
             validate: bool = false;

const POLY:uint(64)=0x0000000000000007;
const PERIOD:int(64) = 1317624576693539401;
// sequence number in stream of random numbers to be used as initial value       
const SEQSEED:int(64) = 834568137686317453;

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
//const    DomA = {0.. # length};

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

//writeln ("init: tablessize = ",tablesize,", tablespace = ",tablespace,", nupdate = ",nupdate);

//
// Print information before main loop
//
if (!validate) {
  writeln("Parallel Research Kernels version ", PRKVERSION);
  writeln("Chapel: Serial Random Access");
  writeln("Table size (shared)    = ", tablesize);
  writeln("Update ratio           = ", update_ratio);
  writeln("Number of updates      = ", nupdate);
  writeln("Vector length          = ", length);
  writeln("Number of iterations   = ", iterations);
}
const    Dom = {0.. # tablesize};
const    DomA = {0.. # nstarts};
var Table: [Dom] int;
var ran: [DomA] uint(64);

for i in 0.. # tablesize { Table[i] = i; }

//
// Main loop
//
timer.start();
var v:  int;
//var val: uint(64);
var val: [DomA] uint(64);
var idx2: [DomA] int;

// do two identical rounds of Random Access to make sure we recover the initial condition   
for round in 0.. # 2 {
  forall j in 0.. # nstarts { 
    ran[j] = PRK_starts (SEQSEED+(nupdate/nstarts)*j); 
    }
  for j in 0.. # nstarts {
    // because we do two rounds, we divide nupdates in two     
    //for (i=0; i<nupdate/(nstarts*2); i++) {
    for i in 0.. # nupdate/(nstarts*2) {
    if (ran[j] < 0)
        then val[j] = POLY;
        else val[j] = 0;
      //ran[j] = (ran[j] << 1) ^ ((s64Int)ran[j] < 0? POLY: 0);
      ran[j] = (ran[j] << 1) ^ val[j];
      idx2[j] = (ran[j] & (tablesize-1)):int;
      Table[idx2[j]] = (Table[idx2[j]]^ran[j]):int;
    }
  }
}
// Timings
random_time = timer.elapsed();
timer.stop();

  /* verification test */
  //for(i=0;i<tablesize;i++) {
  for (i) in DomA {
    if(Table[i] != i:uint(64)) {
      writeln ("Error Table[",i,"]=",Table[i]);
      err +=1;
    }
  }

const epsilon = 1.0E-9;

// output
if (err > 0) {
  writeln("ERROR: number of incorrect table elements: ",err);
  }
else {
  writeln("Solution validates, number of errors: ",err);
  writeln("Rate (GUPs/s): ", epsilon*nupdate/random_time,", time (s) = ",random_time);
}
 

/* Utility routine to start random number generator at nth step            */
proc PRK_starts(m:int):uint(64)
{
var i, j, n:  int; 
var m2: [64] uint; 
var temp, ran: uint(64);
var val: uint(64);

n = m;
do { n += PERIOD; } while (n < 0);
do { n -= PERIOD; } while (n > PERIOD);

if (n == 0) then return 0x1;

  temp = 0x1;
  //for (i=0; i<64; i++) {
  for i in 0.. #64 {
    m2[i] = temp;
    if (temp < 0)
        then val = POLY;
        else val = 0;
    temp = (temp << 1) ^ val;
//writeln ("*1*: i = ",i," m2[",i,"] = ",m2[i],", val = ",val,", temp = ",temp);
    if (temp < 0)
        then val = POLY;
        else val = 0;
    temp = (temp << 1) ^ val;
//writeln ("*2*: i = ",i," m2[",i,"] = ",m2[i],", val = ",val,", temp = ",temp);
  }

  //for (i=62; i>=0; i--)
  for i in 0..62 by -1 do
    { if ((n >> i) & 1) then break; }

  ran = 0x2;
  while (i > 0) {
    temp = 0;
    //for (j=0; j<64; j++)
    for j in 0.. # 64 {
      if (((ran >> j) & 1):uint(64))
         then temp ^= m2[j];
      }
    ran = temp;
    i -= 1;
    if ((n >> i) & 1)
        then val = POLY;
        else val = 0;
    ran = (ran << 1) ^ val;
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


