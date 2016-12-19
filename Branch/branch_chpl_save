//
// Chapel's serial implementation of branch
//
use Time;

extern proc sizeof(e): size_t;
param PRKVERSION = "2.15";

config const numTasks = here.maxTaskPar;
config const iterations : int = 100,
             length : int = 1000,
             branchtype : string = "vector_stop",
             debug: bool = false,
             validate: bool = false;

// config const offset : int = 0; // do we really need offset?? Let's skip it for now.
config var MAXLENGTH = 2000000;
config var SCALAR = 3.0;
config var tileSize: int = 0;

/* the following values are only used as labels */
const VECTOR_STOP = 66;
const VECTOR_GO = 77;
const NO_VECTOR = 88;
const INS_HEAVY = 99;
const WITH_BRANCHES = 1;
const WITHOUT_BRANCHES = 0;
const Dom1 = {0..#5};
const Dom2 = {0..#5,0..#5};

var vector_length: int;   /* length of vector loop containing the branch       */
var nfunc: int;           /* number of functions used in INS_HEAVY option      */
var rank: int;            /* matrix rank used in INS_HEAVY option              */
var branch_time: real;    /* timing parameters                                 */
var no_branch_time: real; /* more timing parameters                            */
var ops: real;            /* double precision representation of integer ops    */
var i: int;               /* dummies                                           */
var aux2: int;             /* dummies                                           */
var branch_type: string;  /* string defining branching type                    */
var btype: int;           /* integer encoding branching type                   */
var total=0: int;         /*                                                   */
var total_ref: int;       /* computed and stored verification values           */

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

vector_length = length;
/*
var total_length = length*2*4;
writeln ("total_length = ", total_length);
*/

// Domains
const    DomA = {0.. # length};

var N : int;
var timer: Timer,
    V    : [DomA] int,
    aux  : [DomA] int,
    Idx  : [DomA] int;

//
// Print information before main loop
//
if (!validate) {
  writeln("Parallel Research Kernels version ", PRKVERSION);
  writeln("Chapel: Serial Branching Bonaza");
  writeln("Vector length          = ", length);
  writeln("Number of iterations   = ", iterations);
  writeln("Branching type         = ", branchtype);
}

// initialization
/* initialize the array with entries with varying signs; array "idx" is only
   used to obfuscate the compiler (i.e. it won't vectorize a loop containing
   indirect referencing). It functions as the identity operator.               */

nfunc = 40;
rank  = 5;

for i in 0.. vector_length-1 {
    V[i]  = 3 - (i&7);
    aux[i] = 0;
    Idx[i]= i;
  }

//
// Main loop
//

timer.start();

  select branchtype {
    when "vector_stop" do
     {
     /* condition vector[idx[i]]>0 inhibits vectorization                     */
     var t = 0;
     do {
        forall (i) in DomA {
          aux[i] = -(3 - (i&7));
          if (V[Idx[i]]>0)
             then V[i] -= 2*V[i];
             else V[i] -= 2*aux[i];
          }
        forall (i) in DomA {
          aux[i] = (3 - (i&7));
          if (V[Idx[i]]>0)
             then V[i] -= 2*V[i];
             else V[i] -= 2*aux[i];
          }
        t +=2;
       } while (t < iterations);
     }
    when "vector_go" do
     {
     /* condition aux>0 allows vectorization */
     var t = 0;
     do {
        forall (i) in DomA {
          aux[i] = -(3 - (i&7));
          if (aux[i]>0)
             then V[i] -= 2*V[i];
             else V[i] -= 2*aux[i];
          }
        forall (i) in DomA {
          aux[i] = (3 - (i&7));
          if (aux[i]>0)
             then V[i] -= 2*V[i];
             else V[i] -= 2*aux[i];
          }
        t +=2;
       } while (t < iterations);
     }
    when "no_vector" do 
     {
     /* condition aux>0 allows vectorization, but indirect idxing inbibits it */
     var t = 0;
/*
     do {
        for i in 0..  vector_length -1 {
        aux2 = -(3 - (i&7));
        if (aux2>0) 
           then V[i] -= 2*V[Idx[i]];
           else V[i] -= 2*aux2;
//writeln ("*1*: t = ",t,", aux2 = ",aux2,"Idx[",i,"] = ",Idx[i], ", V[",Idx[i],"] = ",V[Idx[i]]);
          }
        for i in 0..  vector_length -1 {
          aux = (3 - (i&7));
          if (aux2>0) 
             then V[i] -= 2*V[Idx[i]];
             else V[i] -= 2*aux2;
//writeln ("*2*: t = ",t,", aux2 = ",aux2,"Idx[",i,"] = ",Idx[i], ", V[",Idx[i],"] = ",V[Idx[i]]);
          }
        t +=2;
       } while (t < iterations);
*/
     do {
        forall (i) in DomA {
          aux[i] = -(3 - (i&7));
          if (aux[i]>0)
             then V[i] -= 2*V[Idx[i]];
             else V[i] -= 2*aux[i];
//writeln ("*1*: t = ",t,", aux = ",aux[i],"Idx[",i,"] = ",Idx[i], ", V[",Idx[i],"] = ",V[Idx[i]]);
          }
        forall (i) in DomA {
          aux[i] = (3 - (i&7));
          if (aux[i]>0)
             then V[i] -= 2*V[Idx[i]];
             else V[i] -= 2*aux[i];
//writeln ("*2*: t = ",t,", aux = ",aux[i],"Idx[",i,"] = ",Idx[i], ", V[",Idx[i],"] = ",V[Idx[i]]);
          }
        t +=2;
       } while (t < iterations);
     }
    when "ins_heavy" do
     {
     fill_vec(V, vector_length, iterations, WITH_BRANCHES, nfunc, rank);
     }
    }

branch_time = timer.elapsed();
timer.stop();
    if (branchtype == "ins_heavy") {
      writeln("Number of matrix functions = ", nfunc);
      writeln("Matrix order               = ", rank);
      }


timer.start();

  /* do the whole thing one more time but now without branches */
  select branchtype {
    when "vector_stop" do
     {
     /* condition vector[idx[i]]>0 inhibits vectorization                     */
     var t = 0;
     do {
        forall (i) in DomA {
          aux[i] = -(3 - (i&7));
          V[i] -= (V[i] + aux[i]);
//writeln ("*1*: t = ",t,", aux = ",aux[i],", V[",i,"] = ",V[i]);
          }
        forall (i) in DomA {
          aux[i] = (3 - (i&7));
          V[i] -= (V[i] + aux[i]);
//writeln ("*2*: t = ",t,", aux = ",aux[i],", V[",i,"] = ",V[i]);
          }
        t +=2;
       } while (t < iterations);
     }
    when "vector_go" do 
     {
     /* condition vector[idx[i]]>0 inhibits vectorization                     */
     var t = 0;
     do {
        forall (i) in DomA {
          aux[i] = -(3 - (i&7));
          V[i] -= (V[i] + aux[i]);
//writeln ("*1*: t = ",t,", aux = ",aux[i],", V[",i,"] = ",V[i]);
          }
        forall (i) in DomA {
          aux[i] = (3 - (i&7));
          V[i] -= (V[i] + aux[i]);
//writeln ("*2*: t = ",t,", aux = ",aux[i],", V[",i,"] = ",V[i]);
          }
        t +=2;
       } while (t < iterations);
     }
    when "no_vector" do
     {
     var t = 0;
/*
     do {
        for i in 0..  vector_length -1 {
          aux2 = -(3 - (i&7));
          V[i] -= (V[Idx[i]] + aux2);
//writeln ("*1*: t = ",t,", aux2 = ",aux2,", V[",i,"] = ",V[i]);
          }
        for i in 0..  vector_length -1 {
          aux2 = (3 - (i&7));
          V[i] -= (V[Idx[i]] + aux2);
//writeln ("*2*: t = ",t,", aux2 = ",aux2,", V[",i,"] = ",V[i]);
          }
        t +=2;
       } while (t < iterations);
*/
     do {
        forall (i) in DomA {
          aux[i] = -(3 - (i&7));
          V[i] -= (V[Idx[i]] + aux[i]);
//writeln ("*1*: t = ",t,", aux = ",aux[i],", V[",i,"] = ",V[i]);
          }
        forall (i) in DomA {
          aux[i] = (3 - (i&7));
          V[i] -= (V[Idx[i]] + aux[i]);
//writeln ("*2*: t = ",t,", aux = ",aux[i],", V[",i,"] = ",V[i]);
          }
        t +=2;
       } while (t < iterations);
     }
    when "ins_heavy" do 
     {
     fill_vec(V, vector_length, iterations, WITHOUT_BRANCHES, nfunc, rank);
     }
    }

//
// Analyze and output results
//


// verify correctness */
no_branch_time = timer.elapsed();
timer.stop();
ops = vector_length * iterations;
if (branchtype == "ins_heavy") 
   then ops *= rank*(rank*19 + 6);
   else ops *= 4.0;

//writeln ("ops = ",ops,", rank=",rank,", vector_length = ",vector_length,", iteration = ",iterations);

//for (total = 0, i=0; i<vector_length; i++) total += vector[i];
total = 0;
for i in 0.. vector_length -1 {
  total += V[i];
//writeln ("total = ",total," V[",i,"] = ",V[i]);
  }
writeln ("total = ",total);

/* compute verification values */
var len1 = vector_length%8;
var len2 = vector_length%8-8;
writeln ("len1 = ",len1," len2 = ",len2);

total_ref = ((vector_length%8)*(vector_length%8-8) + vector_length)/2;
writeln ("total_ref = ",total_ref);

// output
if (total == total_ref) {
  writeln("Solution validates");
  writeln("Rate (Mops/s): with branches:", ops/(branch_time*1.E6)," time (s): ",branch_time);
  writeln("Rate (Mops/s): without branches:", ops/(no_branch_time*1.E6)," time (s): ",no_branch_time);
}

proc ABS (val: int) {
  return abs(val);
/*
 if (val < 0)
    then return (val * -1);
    else return val;
*/
}

proc fill_vec(vector, length, iterations, branch, nfunc, rank) {
var a, b: [Dom2] int;
var zero, one: [Dom1] int;
var aux, aux2, i, t: int;

  // return generator values to calling program 
/*
  nfunc = 40;
  rank  = 5;
*/

  if (!branch)
     {
     do {
        //forall (i) in DomA {
        for i in 0.. vector_length -1 {
         aux2 = -(3-(func0(i,a,b)&7));
         V[i] -= (V[i]+aux2);
         }
        //forall (i) in DomA {
        for i in 0.. vector_length -1 {
         aux2 = (3-(func0(i,a,b)&7));
         V[i] -= (V[i]+aux2);
         }
        t +=2;
        } while (t < iterations);
     }
  else 
     {
     //for i in 0.. # 5 { zero[i] = 0; one[i] = i; }
     zero = 0; one = 1; 
     //for (i=0; i<5; i++) { zero[i] = 0; one[i]  = 1; }
     //for (iter=0; iter<iterations; iter+=2) {
     //for (i=0; i<length; i++) {
     a = 6; b = 7;
     a[0,0] = 4; 
     do {
        //forall (i) in DomA {
        for i in 0.. vector_length -1 {
          aux = i%40;
          select aux {
            when 0 do { aux2 = -(3-(func0(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 1 do { aux2 = -(3-(func1(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 2 do { aux2 = -(3-(func2(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 3 do { aux2 = -(3-(func3(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 4 do { aux2 = -(3-(func4(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 5 do { aux2 = -(3-(func5(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 6 do { aux2 = -(3-(func6(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 7 do { aux2 = -(3-(func7(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 8 do { aux2 = -(3-(func8(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 9 do { aux2 = -(3-(func9(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 10 do { aux2 = -(3-(func10(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 11 do { aux2 = -(3-(func11(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 12 do { aux2 = -(3-(func12(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 13 do { aux2 = -(3-(func13(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 14 do { aux2 = -(3-(func14(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 15 do { aux2 = -(3-(func15(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 16 do { aux2 = -(3-(func16(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 17 do { aux2 = -(3-(func17(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 18 do { aux2 = -(3-(func18(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 19 do { aux2 = -(3-(func19(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 20 do { aux2 = -(3-(func20(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 21 do { aux2 = -(3-(func21(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 22 do { aux2 = -(3-(func22(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 23 do { aux2 = -(3-(func23(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 24 do { aux2 = -(3-(func24(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 25 do { aux2 = -(3-(func25(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 26 do { aux2 = -(3-(func26(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 27 do { aux2 = -(3-(func27(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 28 do { aux2 = -(3-(func28(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 29 do { aux2 = -(3-(func29(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 30 do { aux2 = -(3-(func30(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 31 do { aux2 = -(3-(func31(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 32 do { aux2 = -(3-(func32(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 33 do { aux2 = -(3-(func33(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 34 do { aux2 = -(3-(func34(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 35 do { aux2 = -(3-(func35(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 36 do { aux2 = -(3-(func36(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 37 do { aux2 = -(3-(func37(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 38 do { aux2 = -(3-(func38(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 39 do { aux2 = -(3-(func39(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            // default: vector[i] = 0;
            } // end of select
          } // end of forall

        //forall (i) in DomA {
        //for (i=0; i<length; i++) {
        for i in 0.. vector_length -1 {
          aux = i%40;
          select aux {
            when 0 do { aux2 = (3-(func0(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 1 do { aux2 = (3-(func1(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 2 do { aux2 = (3-(func2(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 3 do { aux2 = (3-(func3(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 4 do { aux2 = (3-(func4(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 5 do { aux2 = (3-(func5(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 6 do { aux2 = (3-(func6(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 7 do { aux2 = (3-(func7(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 8 do { aux2 = (3-(func8(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 9 do { aux2 = (3-(func9(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 10 do { aux2 = (3-(func10(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 11 do { aux2 = (3-(func11(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 12 do { aux2 = (3-(func12(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 13 do { aux2 = (3-(func13(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 14 do { aux2 = (3-(func14(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 15 do { aux2 = (3-(func15(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 16 do { aux2 = (3-(func16(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 17 do { aux2 = (3-(func17(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 18 do { aux2 = (3-(func18(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 19 do { aux2 = (3-(func19(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 20 do { aux2 = (3-(func20(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 21 do { aux2 = (3-(func21(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 22 do { aux2 = (3-(func22(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 23 do { aux2 = (3-(func23(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 24 do { aux2 = (3-(func24(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 25 do { aux2 = (3-(func25(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 26 do { aux2 = (3-(func26(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 27 do { aux2 = (3-(func27(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 28 do { aux2 = (3-(func28(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 29 do { aux2 = (3-(func29(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 30 do { aux2 = (3-(func30(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 31 do { aux2 = (3-(func31(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 32 do { aux2 = (3-(func32(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 33 do { aux2 = (3-(func33(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 34 do { aux2 = (3-(func34(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 35 do { aux2 = (3-(func35(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 36 do { aux2 = (3-(func36(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 37 do { aux2 = (3-(func37(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 38 do { aux2 = (3-(func38(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            when 39 do { aux2 = (3-(func39(i,a,b)&7)); vector[i] -= (vector[i]+aux2); }
            // default: vector[i] = 0;
            } // end of select
          } // end of forall
        t +=2;
        } while (t < iterations);
     } // end of else 
} // end of proc fill_vec 

proc funcx(idx: int, x,y) {
  var i, j, x1, x2, x3, err: int;
  var zero: [5] int, one: [5] int;
  //const Dom = {0.. # 5, 0.. # 5};
  var xx, yy: [Dom2] int;
x1 = 0;
/*
  for i in 0.. 4 { 
   for j in 0.. 4 {
   x1 +=1; 
    xx[i][j] = x1; yy[i][j] = x1; }
   }
*/
 j = 0;
  xx = 3;
  yy = 4;
  x[j,j] = 88;

/*
  for i in 0..3 {
   for j in 0..3 {
*/
  for (i) in Dom2 {
writeln ("funcx: a[",i,"][",j,"] = ",x[i]);
  } 
return 1;
}

//proc func0(idx: int, a: [5][5] int, b: [5][5] int) {
//proc func0(idx: int, a: [{0..#4,0..#4}] int, b: [{0..#4,0..#4}] int) {
proc func0(idx: int, a, b) {
  var i, j, x1, x2, x3, err: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  err = 0;
  x1 = 0 + idx;  
  x2 = 38357;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
/*
writeln ("func0: idx = ",idx,", x1 = ",x1,",x2 = ",x2,", x3 = ",x3);
writeln (" a[0,0] = ",a[0,0]);
*/
  a[0,0] = one[x3];

  x1 = 6666 + idx;  
  x2 = 67800;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;  
  x2 = 20214;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;  
  x2 = 49657;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 2071;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;  
  x2 = 58571;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;  
  x2 = 10985;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;  
  x2 = 40428;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 69871;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;  
  x2 = 22285;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;  
  x2 = 1756;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;  
  x2 = 31199;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 60642;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;  
  x2 = 13056;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;  
  x2 = 42499;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;  
  x2 = 21970;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 51413;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;  
  x2 = 3827;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;  
  x2 = 33270;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;  
  x2 = 62713;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 42184;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;  
  x2 = 71627;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;  
  x2 = 24041;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;  
  x2 = 53484;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;  
  x2 = 5898;
  x3 = (x1 + (0+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  //for (j=0; j<5; j++) for (i=0; i<5; i++)
/*
  for j in 0..  5 {
   for i in 0..  5 { b[j][i] = (a[i][j]+a[j][i])/2; }
*/
   for (i,j) in Dom2 { b[j,i] = (a[i,j]+a[j,i])/2; }
  //for (j=0; j<5; j++) for (i=0; i<5; i++)
/*
  for j in 0.. 5 {
   for i in 0.. 5 { 
*/
   for (j,i) in Dom2 {
    if (i != j) then err += ABS(b[j,i]); 
    }
  //for (i=0; i<5; i++) err += ABS(1-b[i][i]);
  //for i in 0.. # 5 {err += ABS(1-b[i][i]);}
  for (i,j) in Dom2 {err += ABS(1-b[i,i]);}
  if (err) 
  then return(0);
  else return(idx);
}
 
proc func20(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;  
  x2 = 38357;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;  
  x2 = 67800;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;  
  x2 = 20214;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;  
  x2 = 49657;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 2071;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;  
  x2 = 58571;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;  
  x2 = 10985;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;  
  x2 = 40428;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 69871;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;  
  x2 = 22285;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;  
  x2 = 1756;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;  
  x2 = 31199;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 60642;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;  
  x2 = 13056;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;  
  x2 = 42499;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;  
  x2 = 21970;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 51413;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;  
  x2 = 3827;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;  
  x2 = 33270;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;  
  x2 = 62713;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;  
  x2 = 42184;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;  
  x2 = 71627;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;  
  x2 = 24041;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;  
  x2 = 53484;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;  
  x2 = 5898;
  x3 = (x1 + (20+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  //for (j=0; j<5; j++) for (i=0; i<5; i++)
  for j in 0.. 5 {
   for i in 0.. 5 { b[j,i] = (a[i,j]+a[j,i])/2; }
   } 
  //for (j=0; j<5; j++) for (i=0; i<5; i++)
  for j in 0.. 5 {
   for j in 0.. 5 { if (i != j) then err += ABS(b[j,i]);}
   }
  if (err) 
  then return(0);
  else return(idx);
}

proc func1(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (1+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func21(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (21+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);

}

proc func2(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (2+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func22(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (22+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func3(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (3+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func23(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (23+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func4(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (4+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func24(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (24+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func5(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (5+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func25(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (25+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func6(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (6+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func26(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (26+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func7(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (7+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func27(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (27+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func8(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (8+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func28(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (28+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func9(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (9+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func29(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (29+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func10(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (10+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func30(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (30+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func11(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (11+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func31(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (31+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func12(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (12+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func32(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (32+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func13(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (13+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func33(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (33+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func14(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (14+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func34(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (34+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func15(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (15+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func35(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (35+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func16(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (16+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func36(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (36+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func17(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (17+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func37(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (37+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func18(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (18+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func38(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (38+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func19(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (19+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

proc func39(idx: int, a, b) {
  var i, j, x1, x2, x3, err=0: int;
  var zero, one: [Dom1] int;
  zero = 0; one = 1;

  x1 = 0 + idx;
  x2 = 38357;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,0] = one[x3];

  x1 = 6666 + idx;
  x2 = 67800;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,1] = zero[x3];

  x1 = 4943 + idx;
  x2 = 20214;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,2] = zero[x3];

  x1 = 3220 + idx;
  x2 = 49657;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,3] = zero[x3];

  x1 = 1497 + idx;
  x2 = 2071;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[0,4] = zero[x3];

  x1 = 6666 + idx;
  x2 = 58571;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,0] = zero[x3];

  x1 = 4943 + idx;
  x2 = 10985;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,1] = one[x3];

  x1 = 3220 + idx;
  x2 = 40428;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,2] = zero[x3];

  x1 = 1497 + idx;
  x2 = 69871;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,3] = zero[x3];

  x1 = 8163 + idx;
  x2 = 22285;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[1,4] = zero[x3];

  x1 = 4943 + idx;
  x2 = 1756;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,0] = zero[x3];

  x1 = 3220 + idx;
  x2 = 31199;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,1] = zero[x3];

  x1 = 1497 + idx;
  x2 = 60642;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,2] = one[x3];

  x1 = 8163 + idx;
  x2 = 13056;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,3] = zero[x3];

  x1 = 6440 + idx;
  x2 = 42499;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[2,4] = zero[x3];

  x1 = 3220 + idx;
  x2 = 21970;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,0] = zero[x3];

  x1 = 1497 + idx;
  x2 = 51413;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,1] = zero[x3];

  x1 = 8163 + idx;
  x2 = 3827;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,2] = zero[x3];

  x1 = 6440 + idx;
  x2 = 33270;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,3] = one[x3];

  x1 = 4717 + idx;
  x2 = 62713;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[3,4] = zero[x3];

  x1 = 1497 + idx;
  x2 = 42184;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,0] = zero[x3];

  x1 = 8163 + idx;
  x2 = 71627;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,1] = zero[x3];

  x1 = 6440 + idx;
  x2 = 24041;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,2] = zero[x3];

  x1 = 4717 + idx;
  x2 = 53484;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,3] = zero[x3];

  x1 = 2994 + idx;
  x2 = 5898;
  x3 = (x1 + (39+1)*x2) % 5;
  x1 += (x2 - x3 + 5 ) % 5;
  x2 += (x1 - 5*x3 + 7 * 5 ) % 5;
  x3 = (x1 + 4*x2) % 5;
  a[4,4] = one[x3];

  for j in 0.. 5 { for i in 0.. 5 { if (i != j) then err += ABS(b[j,i]); } }
  for i in 0.. # 5 {err += ABS(1-b[i,i]);}
  if (err)
  then return(0);
  else return(idx);
}

