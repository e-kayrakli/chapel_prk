//
// Chapel's serial implementation of branch
//
use Time;
use configs;
use procs;

//
// Process and test input configs
//
if iterations < 1 then
halt("ERROR: iterations must be >= 1: ", iterations);

if length < 0 then
halt("ERROR: vector length must be >= 1: ", length);

vector_length = length;

// Domains
DomA = {0.. # length};

var N : int;
var timer: Timer,
    V    : [DomA] int,
    aux  : [DomA] int,
    Idx  : [DomA] int;

//
// Print information before main loop
//
writeln("Parallel Research Kernels version ", PRKVERSION);
writeln("Chapel: Serial Branching Bonaza");
writeln("Vector length          = ", length);
writeln("Number of iterations   = ", iterations);
writeln("Branching type         = ", branchType);

// initialization
nfunc = 40;
rank  = 5;

for i in 0.. vector_length-1 {
  V[i]  = 3 - (i&7);
  aux[i] = 0;
  Idx[i]= i;
}

//set branchType int
const branchTypeInt = if branchType == "vector_stop" then 1
                      else if branchType == "vector_go" then 2
                      else if branchType == "no_vector" then 3
                      else if branchType == "ins_heavy" then 4
                      else -1;

if branchTypeInt == -1 then
  halt("Invalid branch type: ", branchType);

//
// Main loop
//
timer.start();

select branchTypeInt {

  when 1 {
    /*condition vector[idx[i]]>0 inhibits vectorization*/
    var t = 0;
    do {
      forall i in DomA {
        aux[i] = -(3 - (i&7));
        if V[Idx[i]]>0 then
          V[i] -= 2*V[i];
        else
          V[i] -= 2*aux[i];
      }
      forall i in DomA {
        aux[i] = (3 - (i&7));
        if V[Idx[i]]>0 then
          V[i] -= 2*V[i];
        else
          V[i] -= 2*aux[i];
      }
      t +=2;
    } while (t < iterations);
  }

  when 2 {
    /* condition aux>0 allows vectorization */
    var t = 0;
    do {
      forall i in DomA {
        aux[i] = -(3 - (i&7));
        if aux[i]>0 then
          V[i] -= 2*V[i];
        else
          V[i] -= 2*aux[i];
      }
      forall i in DomA {
        aux[i] = (3 - (i&7));
        if aux[i]>0 then
          V[i] -= 2*V[i];
        else
          V[i] -= 2*aux[i];
      }
      t +=2;
    } while (t < iterations);
  }

  when 3 {
    /*condition aux>0 allows vectorization*/
    /*but indirect idxing inbibits it */
    var t = 0;
    do {
      forall i in DomA {
        aux[i] = -(3 - (i&7));
        if aux[i]>0 then
          V[i] -= 2*V[Idx[i]];
        else
          V[i] -= 2*aux[i];
      }
      forall i in DomA {
        aux[i] = (3 - (i&7));
        if aux[i]>0 then
          V[i] -= 2*V[Idx[i]];
        else
          V[i] -= 2*aux[i];
      }
      t +=2;
    } while (t < iterations);
  }

  when 4 {
    fill_vec(V, vector_length, iterations, WITH_BRANCHES, nfunc, rank);
  }
}

branch_time = timer.elapsed();
timer.stop();
if branchTypeInt == 4 {
  writeln("Number of matrix functions = ", nfunc);
  writeln("Matrix order               = ", rank);
}


timer.start();

/* do the whole thing one more time but now without branches */
select branchTypeInt {

  when 1 {
    /* condition vector[idx[i]]>0 inhibits vectorization                     */
    var t = 0;
    do {
      forall i in DomA {
        aux[i] = -(3 - (i&7));
        V[i] -= (V[i] + aux[i]);
      }
      forall (i) in DomA {
        aux[i] = (3 - (i&7));
        V[i] -= (V[i] + aux[i]);
      }
      t +=2;
    } while (t < iterations);
  }

  when 2 {
    /* condition vector[idx[i]]>0 inhibits vectorization*/
    var t = 0;
    do {
      forall i in DomA {
        aux[i] = -(3 - (i&7));
        V[i] -= (V[i] + aux[i]);
      }
      forall i in DomA {
        aux[i] = (3 - (i&7));
        V[i] -= (V[i] + aux[i]);
      }
      t +=2;
    } while (t < iterations);
  }

  when 3 {
    var t = 0;
    do {
      forall i in DomA {
        aux[i] = -(3 - (i&7));
        V[i] -= (V[Idx[i]] + aux[i]);
      }
      forall i in DomA {
        aux[i] = (3 - (i&7));
        V[i] -= (V[Idx[i]] + aux[i]);
      }
      t +=2;
    } while (t < iterations);
  }

  when 4 {
    fill_vec(V, vector_length, iterations, WITHOUT_BRANCHES, nfunc,
        rank);
  }
}

//
// Analyze and output results
//


// verify correctness */
no_branch_time = timer.elapsed();
timer.stop();
ops = vector_length * iterations;
if branchTypeInt == 4 then
ops *= rank*(rank*19 + 6);
else
ops *= 4.0;

total = 0;
for i in 0.. vector_length -1 {
  total += V[i];
}
writeln ("total = ",total);

/* compute verification values */
var len1 = vector_length%8;
var len2 = vector_length%8-8;
writeln ("len1 = ",len1," len2 = ",len2);

total_ref = ((vector_length%8)*(vector_length%8-8) + vector_length)/2;
writeln ("total_ref = ",total_ref);

// output
if total == total_ref {
  writeln("Solution validates");
  writeln("Rate (Mops/s): with branches:", ops/(branch_time*1.E6)," time (s): ",branch_time);
  writeln("Rate (Mops/s): without branches:", ops/(no_branch_time*1.E6)," time (s): ",no_branch_time);
}

proc fill_vec(vector, length, iterations, branch, nfunc, rank) {
  var a, b: [Dom2] int;
  var zero, one: [Dom1] int;
  var aux, aux2, i, t: int;

  if (!branch) {
    do {
      for i in 0.. vector_length -1 {
        aux2 = -(3-(func0(i,a,b)&7));
        V[i] -= (V[i]+aux2);
      }
      for i in 0.. vector_length -1 {
        aux2 = (3-(func0(i,a,b)&7));
        V[i] -= (V[i]+aux2);
      }
      t +=2;
    } while (t < iterations);
  }
  else {
    //for i in 0.. # 5 { zero[i] = 0; one[i] = i; }
    zero = 0; one = 1; 
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

