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
DomA = {0..#length};


var timer: Timer;
var total: atomic int;

//
// Print information before main loop
//
writeln("Parallel Research Kernels version ", PRKVERSION);
writeln("Max parallelism        = ", here.maxTaskPar);
writeln("Vector length          = ", length);
writeln("Number of iterations   = ", iterations);
writeln("Branching type         = ", branchType);

// initialization
nfunc = 40;
rank  = 5;

const parIterations = iterations*here.maxTaskPar;


//set branchType int
const branchTypeInt = if branchType == "vector_stop" then 1
                      else if branchType == "vector_go" then 2
                      else if branchType == "no_vector" then 3
                      else if branchType == "ins_heavy" then 4
                      else -1;

if branchTypeInt == -1 then halt("Invalid branch type: ", branchType);

coforall tid in 0..#here.maxTaskPar {
  var V    : [DomA] dataType;
  var Idx  : [DomA] dataType;
  for i in 0.. vector_length-1 {
    V[i]  = (3 - (i&7)):dataType;
    /*aux[i] = 0;*/
    Idx[i]= i:dataType;
  }
  //
  // Main loop
  //
  if tid==0 then timer.start();

  select branchTypeInt {

    when 1 { //vector_stop
      /*condition vector[idx[i]]>0 inhibits vectorization*/
      for t in 0..#parIterations by 2 {
        for i in DomA {
          var aux = (-(3 - (i&7))):dataType;
          if V[Idx[i]]>0 then
            V[i] -= 2*V[i];
          else
            V[i] -= 2*aux;
        }
        for i in DomA {
          var aux = (3 - (i&7)):dataType;
          if V[Idx[i]]>0 then
            V[i] -= 2*V[i];
          else
            V[i] -= 2*aux;
        }
      }
    }

    when 2 { //vector_go
      /* condition aux>0 allows vectorization */
      for t in 0..#parIterations by 2 {
        for i in DomA {
          var aux = -(3 - (i&7)):dataType;
          if aux>0 then
            V[i] -= 2*V[i];
          else
            V[i] -= 2*aux;
        }
        for i in DomA {
          var aux = (3 - (i&7)):dataType;
          if aux>0 then
            V[i] -= 2*V[i];
          else
            V[i] -= 2*aux;
        }
      }
    }

    when 3 { //no_vector
      /*condition aux>0 allows vectorization*/
      /*but indirect idxing inbibits it */
      for t in 0..#parIterations by 2 {
        for i in DomA {
          var aux = -(3 - (i&7)):dataType;
          if aux>0 then
            V[i] -= 2*V[Idx[i]];
          else
            V[i] -= 2*aux;
        }
        for i in DomA {
          var aux = (3 - (i&7)):dataType;
          if aux>0 then
            V[i] -= 2*V[Idx[i]];
          else
            V[i] -= 2*aux;
        }
      }
    }

    when 4 { //ins_heavy
      fill_vec(V, vector_length, parIterations, WITH_BRANCHES, nfunc, rank);
    }
  }

  if tid == 0 {
    branch_time = timer.elapsed();
    timer.stop();
    timer.clear();
    if branchTypeInt == 4 {
      writeln("Number of matrix functions = ", nfunc);
      writeln("Matrix order               = ", rank);
    }
    timer.start();
  }



  /* do the whole thing one more time but now without branches */
  select branchTypeInt {

    when 1 { //vector_stop
      /* condition vector[idx[i]]>0 inhibits vectorization */
      for t in 0..#parIterations by 2 {
        for i in DomA {
          var aux = -(3 - (i&7)):dataType;
          V[i] -= V[i] + aux;
        }
        for i in DomA {
          var aux = (3 - (i&7)):dataType;
          V[i] -= V[i] + aux;
        }
      }
    }

    when 2 { //vector_go
      /* condition vector[idx[i]]>0 inhibits vectorization*/
      for t in 0..#parIterations by 2 {
        for i in DomA {
          var aux = -(3 - (i&7)):dataType;
          V[i] -= (V[i] + aux);
        }
        for i in DomA {
          var aux = (3 - (i&7)):dataType;
          V[i] -= (V[i] + aux);
        }
      }
    }

    when 3 { //no_vector
      for t in 0..#parIterations by 2 {
        for i in DomA {
          var aux = -(3 - (i&7)):dataType;
          V[i] -= (V[Idx[i]] + aux);
        }
        for i in DomA {
          var aux = (3 - (i&7)):dataType;
          V[i] -= (V[Idx[i]] + aux);
        }
      }
    }

    when 4 { //inst_heavy
      fill_vec(V, vector_length, parIterations, WITHOUT_BRANCHES, nfunc,
          rank);
    }
  }

//
// Analyze and output results
//

  if tid == 0 {
    no_branch_time = timer.elapsed();
    timer.stop();
  }
  // verify correctness */
  total.add(+ reduce V);
}

ops = vector_length * parIterations;
if branchTypeInt == 4 then
ops *= rank*(rank*19 + 6);
else
ops *= 4.0;

writeln ("total = ",total);

/* compute verification values */
var len1 = vector_length%8;
var len2 = vector_length%8-8;
writeln ("len1 = ",len1," len2 = ",len2);

total_ref = ((vector_length%8)*(vector_length%8-8) +
    vector_length)/2*here.maxTaskPar;

// output
if total.read() == total_ref {
  writeln("Solution validates");
  writeln("Rate (Mops/s): with branches:", ops/(branch_time*1.E6)," time (s): ",branch_time);
  writeln("Rate (Mops/s): without branches:", ops/(no_branch_time*1.E6)," time (s): ",no_branch_time);
}
else {
  writeln("Validation failed: Reference Total = ", total_ref,
      " Total = ", total.read());
}

proc fill_vec(vector, length, parIterations, branch, nfunc, rank) {
  var a, b: [Dom2] dataType;
  var zero, one: [Dom1] dataType;
  var aux, aux2, i, t: dataType;

  if (!branch) {
    do {
      for i in 0.. vector_length -1 {
        aux2 = -(3-(func0(i:dataType,a,b)&7)):dataType;
        vector[i] -= (vector[i]+aux2);
      }
      for i in 0.. vector_length -1 {
        aux2 = (3-(func0(i:dataType,a,b)&7)):dataType;
        vector[i] -= (vector[i]+aux2);
      }
      t +=2;
    } while (t < parIterations);
  }
  else {
    //for i in 0.. # 5 { zero[i] = 0; one[i] = i; }
    zero = 0; one = 1; 
    a = 6; b = 7;
    a[0,0] = 4; 
    do {
      //forall (i) in DomA {
      for i in 0.. vector_length-1 {
        const ii = i:dataType;
        aux = ii%40;
        select aux {
          when 0 do { aux2 = -(3-(func0(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 1 do { aux2 = -(3-(func1(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 2 do { aux2 = -(3-(func2(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 3 do { aux2 = -(3-(func3(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 4 do { aux2 = -(3-(func4(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 5 do { aux2 = -(3-(func5(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 6 do { aux2 = -(3-(func6(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 7 do { aux2 = -(3-(func7(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 8 do { aux2 = -(3-(func8(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 9 do { aux2 = -(3-(func9(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 10 do { aux2 = -(3-(func10(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 11 do { aux2 = -(3-(func11(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 12 do { aux2 = -(3-(func12(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 13 do { aux2 = -(3-(func13(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 14 do { aux2 = -(3-(func14(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 15 do { aux2 = -(3-(func15(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 16 do { aux2 = -(3-(func16(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 17 do { aux2 = -(3-(func17(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 18 do { aux2 = -(3-(func18(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 19 do { aux2 = -(3-(func19(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 20 do { aux2 = -(3-(func20(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 21 do { aux2 = -(3-(func21(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 22 do { aux2 = -(3-(func22(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 23 do { aux2 = -(3-(func23(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 24 do { aux2 = -(3-(func24(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 25 do { aux2 = -(3-(func25(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 26 do { aux2 = -(3-(func26(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 27 do { aux2 = -(3-(func27(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 28 do { aux2 = -(3-(func28(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 29 do { aux2 = -(3-(func29(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 30 do { aux2 = -(3-(func30(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 31 do { aux2 = -(3-(func31(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 32 do { aux2 = -(3-(func32(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 33 do { aux2 = -(3-(func33(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 34 do { aux2 = -(3-(func34(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 35 do { aux2 = -(3-(func35(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 36 do { aux2 = -(3-(func36(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 37 do { aux2 = -(3-(func37(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 38 do { aux2 = -(3-(func38(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          when 39 do { aux2 = -(3-(func39(ii,a,b)&7):dataType); vector[ii] -= (vector[ii]+aux2); }
          // default: vector[i] = 0;
        } // end of select
      } // end of forall

      //forall (i) in DomA {
      //for (i=0; i<length; i++) {
      for i in 0.. vector_length -1 {
        const ii = i:dataType;
        aux = ii%40;
        select aux {
          when 0 do { aux2 = (3-(func0(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 1 do { aux2 = (3-(func1(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 2 do { aux2 = (3-(func2(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 3 do { aux2 = (3-(func3(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 4 do { aux2 = (3-(func4(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 5 do { aux2 = (3-(func5(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 6 do { aux2 = (3-(func6(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 7 do { aux2 = (3-(func7(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 8 do { aux2 = (3-(func8(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 9 do { aux2 = (3-(func9(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 10 do { aux2 = (3-(func10(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 11 do { aux2 = (3-(func11(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 12 do { aux2 = (3-(func12(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 13 do { aux2 = (3-(func13(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 14 do { aux2 = (3-(func14(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 15 do { aux2 = (3-(func15(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 16 do { aux2 = (3-(func16(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 17 do { aux2 = (3-(func17(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 18 do { aux2 = (3-(func18(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 19 do { aux2 = (3-(func19(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 20 do { aux2 = (3-(func20(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 21 do { aux2 = (3-(func21(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 22 do { aux2 = (3-(func22(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 23 do { aux2 = (3-(func23(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 24 do { aux2 = (3-(func24(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 25 do { aux2 = (3-(func25(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 26 do { aux2 = (3-(func26(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 27 do { aux2 = (3-(func27(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 28 do { aux2 = (3-(func28(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 29 do { aux2 = (3-(func29(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 30 do { aux2 = (3-(func30(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 31 do { aux2 = (3-(func31(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 32 do { aux2 = (3-(func32(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 33 do { aux2 = (3-(func33(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 34 do { aux2 = (3-(func34(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 35 do { aux2 = (3-(func35(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 36 do { aux2 = (3-(func36(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 37 do { aux2 = (3-(func37(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 38 do { aux2 = (3-(func38(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          when 39 do { aux2 = (3-(func39(ii,a,b)&7)):dataType; vector[ii] -= (vector[ii]+aux2); }
          // default: vector[i] = 0;
        } // end of select
      } // end of forall
      t +=2;
    } while (t < parIterations);
  } // end of else
} // end of proc fill_vec


