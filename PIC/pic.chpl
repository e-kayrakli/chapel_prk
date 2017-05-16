use Time;
use BlockDist;
use StencilDist;
use DistributedUList;
use CommDiagnostics;

extern proc LCG_init();
extern proc random_draw(x: c_double): uint(64);

param PRKVERSION = "2.17";
param REL_X = 0.5;
param REL_Y = 0.5;
param DT = 1.0;
param Q = 1.0;
param MASS_INV = 1.0;
param epsilon = 0.000001;


config param useBlockDist = false;
config param useList = false;
config param commDiag = true;
config const verboseCommDiag = false;
config const redist = false;
config const verify = false;
config const localAdd = true;

config const detailTiming = false; // TODO make this param

if useBlockDist && useList then
  halt("At most one of useBlockDist and useList can be set");

config const L = 10; // grid size
config var n = 10; // particles requested
config const k = 1;
config const m = 1;
config const iterations = 10;
config const debug = false;
config const particleMode = "SINUSOIDAL";

const gridSpace = {0..#(L+1), 0..#(L+1)};

// for geomteric initialization
config const rho = 1.0;

// for linear initialization
config const alpha = 0.5;
config const beta = 0.5;

// for patch initialization
record bbox {
  var left: int,
      right: int,
      bottom: int,
      top: int;
}

// default patch is the full grid. This will guarantee that if
// particleMode == PATCH we'll get a uniform random distribution by
// default
config const initPatchLeft = gridSpace.dim(2).low;
config const initPatchRight = gridSpace.dim(2).high;
config const initPatchBottom = gridSpace.dim(1).low;
config const initPatchTop= gridSpace.dim(1).high;

const patch = new bbox(initPatchLeft,
                       initPatchRight,
                       initPatchBottom,
                       initPatchTop);

const gridPatch = new bbox(0, (L+1), 0, (L+1));

record particle {
  var x: real;
  var y: real;
  var v_x: real;
  var v_y: real;
  var q: real;

  var x0: real;
  var y0: real;

  var k: int;
  var m: int;
}

writeln("Parallel Research Kernels Version ", PRKVERSION);
writeln("Chapel Particle-in-Cell execution on 2D grid");
writeln("Max parallelism                = ", here.maxTaskPar);
writeln("Grid Size                      = ", L);
writeln("Number of particles requested  = ", n);
writeln("Number of time steps           = ", iterations);
writeln("Initialization mode            = ", particleMode);
select particleMode {
  when "GEOMETRIC" do
    writeln("\tAttenuation factor           = ", rho);
  when "LINEAR" {
    writeln("\tNegative Slope               = ", alpha);
    writeln("\tOffset                       = ", beta);
  }
  when "PATCH" {
    writeln("\tBounding box                 = ", (patch.left,
                                                  patch.right,
                                                  patch.bottom,
                                                  patch.top));
  }
}
writeln("Particle charge semi-increment = ", k);
writeln("Vertical velocity              = ", m);

var Qgrid = initializeGrid(L);

var initTimer = new Timer();
var finishDistTimer = new Timer();
initTimer.start();
var particles =
  if particleMode=="GEOMETRIC" then   initializeGeometric() else
  if particleMode=="SINUSOIDAL" then  initializeSinusoidal() else
  if particleMode=="LINEAR" then      initializeLinear() else
                                      initializePatch();

if useList then particles.finishAdd();
initTimer.stop();
finishDistTimer.start();
finishDistribution();
finishDistTimer.stop();



writeln("Number of particles placed : ", particles.size);
writeln("\t\tInit time                : ", initTimer.elapsed(), "\n",
        "\t\tFinish distribution time : ", finishDistTimer.elapsed());
/*if debug && useList {*/
  /*writeln("Initial list");*/
  /*particles.print();*/
/*}*/
var t = new Timer();
var compTimer = new Timer();
var redistTimer = new Timer();

if commDiag {
  startCommDiagnostics();
  if verboseCommDiag then startVerboseComm();
}
for niter in 0..iterations {

  if niter == 1 then t.start();

  if detailTiming then compTimer.start();
  forall p in particles.redistIter() {

    local {
      const (fx, fy) = computeTotalForce(p);
      const ax = fx * MASS_INV;
      const ay = fy * MASS_INV;

      p.x = mod(p.x + p.v_x*DT + 0.5*ax*DT*DT + L, L);
      p.y = mod(p.y + p.v_y*DT + 0.5*ay*DT*DT + L, L);

      p.v_x += ax * DT;
      p.v_y += ay * DT;
    }
  }
  if detailTiming then compTimer.stop();
  if useList {
    if detailTiming then redistTimer.start();
    if redist then particles.redistribute();
    if detailTiming then redistTimer.stop();
    if debug {
      writeln("Post redist:");
      particles.print();
    }
  }
}
if commDiag {
  particles.printCommMatrix();
  if verboseCommDiag then stopVerboseComm();
  stopCommDiagnostics();
  writeln(getCommDiagnostics());
}
t.stop();

if useList then particles.printTimeStats();

if verify {
  for p in particles {
    if !verifyParticle(p) then
      writeln("Verification failed");
  }
}

writeln("Verification succesful");

if detailTiming then
  writeln("Computation time : " , compTimer.elapsed(),
        "\nRedistribution time : " , redistTimer.elapsed());

const avgTime = t.elapsed()/iterations;
writeln("Rate (Mparticles_moved/s): ", 1.0e-6*(n/avgTime));

proc initializeGrid(L) {
  /*const gridDom = gridSpace dmapped Block(gridSpace);*/
  const gridDom = gridSpace dmapped Stencil(gridSpace, fluff=(1,1));
  var grid: [gridDom] real;

  for (x,y) in grid.domain {
    /*grid[y,x] = if x%2==0 then Q else -Q;*/
    grid[x,y] = if y%2==0 then Q else -Q;
  }

  /*for x in grid.domain.dim(1) {*/
    /*for y in grid.domain.dim(2) {*/
      /*write(grid[x,y].locale.id, " ");*/
    /*}*/
    /*writeln();*/
  /*}*/
  grid.updateFluff();
  return grid;
}

inline proc getParticleDomain(size) {
  const space = {0..#size};
  const dom = space dmapped if useBlockDist then new dmap(new Block(space))
                                            else defaultDist;

  return dom;
}

record Locator {
  var dist;
  var locIdCache: [dist.targetLocales().domain] here.id.type;

  proc Locator(dist) {
    for (l,c) in zip(dist.targetLocales(), locIdCache) do
      c=l.id;
  }

  inline proc getLocaleID(const ref elt: particle) {
    /*return dist._value.targetLocales(*/
          /*dist._value.targetLocsIdx((elt.x:int+1,elt.y:int+1))).id;*/
    return locIdCache[
          dist._value.targetLocsIdx((elt.x:int+1,elt.y:int+1))];
  }

  proc clone() {
    return new Locator(dist.clone());
  }
}

inline proc getParticleContainer(size) {
  if useList {
    var particles = new DistributedUnorderedList(eltType=particle,
                              locator = new Locator(Qgrid.domain.dist));
    return particles;
  }
  else {
    var particles: [getParticleDomain(size)] particle;
    return particles;
  }
}

proc initializeGeometric() {

  const A = n * ((1.0-rho) / (1.0-(rho**L))) / L:real;
  LCG_init();


  var nPlaced = 0;
  for (x,y) in {0..#L, 0..#L} do
    nPlaced += random_draw(getSeed(x)):int;

  /*const particleDom = getParticleDomain(nPlaced);*/
  /*var particles: [particleDom] particle;*/
  
  var particles = getParticleContainer(nPlaced);

  LCG_init();

  var pIdx = 0;
  for (x,y) in {0..#L, 0..#L} {
    // TODO without cast this creates a seg fault and overflow
    // warning with no --fast. Investigate for possible bug. Engin
    const actual_particles = random_draw(getSeed(x)):int;
    placeParticles(particles, pIdx, actual_particles, x, y);
  }
  
  return particles;

  inline proc getSeed(x) {
    return A * (rho**x);
  }
}

proc initializeSinusoidal() {

  const step = pi/L;

  LCG_init();

  var nPlaced = 0;

  for (x,y) in {0..#L, 0..#L} do
    nPlaced += random_draw(getSeed(x)):int;

  /*const particleDom = getParticleDomain(nPlaced);*/
  /*var particles: [particleDom] particle;*/

  var particles = getParticleContainer(nPlaced);

  LCG_init();

  // pIdx = pi in OpenMP code
  var pIdx = 0;
  for (x,y) in {0..#L, 0..#L} {
    // TODO without cast this creates a seg fault and overflow
    // warning with no --fast. Investigate for possible bug. Engin
    const actual_particles = random_draw(getSeed(x)):int;
    placeParticles(particles, pIdx, actual_particles, x, y);
  }
  
  return particles;

  inline proc getSeed(x) {
    return 2.0*(cos(x*step)**2)*n/(L**2);
  }
}

proc initializeLinear() {

  const step = 1.0/L;
  const total_weight = beta*L-alpha*0.5*step*L*(L-1);

  var nPlaced = 0;

  LCG_init();

  for (x,y) in {0..#L, 0..#L} do
    nPlaced += random_draw(getSeed(x)):int;

  /*const particleDom = getParticleDomain(nPlaced);*/
  /*var particles: [particleDom] particle;*/

  var particles = getParticleContainer(nPlaced);

  LCG_init();

  var pIdx = 0;
  for (x,y) in {0..#L, 0..#L} {
    // TODO without cast this creates a seg fault and overflow
    // warning with no --fast. Investigate for possible bug. Engin
    const actual_particles = random_draw(getSeed(x)):int;
    placeParticles(particles, pIdx, actual_particles, x, y);
  }

  return particles;

  inline proc getSeed(x) {
    return n * ((beta - alpha * step * x:real)/total_weight)/L;
  }
}

proc initializePatch() {

  if badPatch(patch, gridPatch) then
    halt("Bad patch given");

  const total_cells  = (patch.right - patch.left+1)*(patch.top -
      patch.bottom+1);
  const particles_per_cell = (1.0*n/total_cells);

  var nPlaced = 0;
  LCG_init();

  for (x,y) in {0..#L, 0..#L} {
    const actual_particles = random_draw(particles_per_cell):int;
    if !outsidePatch(x, y) then
      nPlaced += actual_particles;
  }

  var particles = getParticleContainer(nPlaced);

  LCG_init();

  const particleCreateDom = {0..#L, 0..#L};

  var pIdx = 0;
  if useList && localAdd {
    for l in Locales do on l {
      for (x,y) in Qgrid.localSubdomain()[particleCreateDom] {
        // TODO without cast this creates a seg fault and overflow
        // warning with no --fast. Investigate for possible bug. Engin
        const actual_particles = random_draw(particles_per_cell):int;
        if !outsidePatch(x, y) {
          placeParticles(particles, pIdx, actual_particles, x, y,
              useAddHere=true);
        }
      }
    }
    particles.redistribute();
  }
  else {
    for (x,y) in {0..#L, 0..#L} {
      // TODO without cast this creates a seg fault and overflow
      // warning with no --fast. Investigate for possible bug. Engin
      const actual_particles = random_draw(particles_per_cell):int;
      if !outsidePatch(x, y) {
        placeParticles(particles, pIdx, actual_particles, x, y);
      }
    }
  }
  
  return particles;

  inline proc outsidePatch(x, y) {
    return x<patch.left   || x>patch.right ||
            y<patch.bottom || y>patch.top;
  }

  proc badPatch(patch, patch_contain) {
    if patch.left>=patch.right || patch.bottom>=patch.top then
      return true;
    if patch.left  <patch_contain.left   ||
      patch.right>patch_contain.right then
        return true;
    if patch.bottom<patch_contain.bottom ||
      patch.top > patch_contain.top then
        return true;
    return false;
  }
}

proc finishDistribution() {
  forall p in particles {
    var x_coord = p.x;
    var y_coord = p.y;
    var rel_x = mod(x_coord, 1.0);
    var rel_y = mod(y_coord, 1.0);

    var x = x_coord:uint;
    var r1_sq = rel_y * rel_y + rel_x * rel_x;
    var r2_sq = rel_y * rel_y + (1.0-rel_x) * (1.0-rel_x);
    var cos_theta = rel_x/sqrt(r1_sq);
    var cos_phi = (1.0-rel_x)/sqrt(r2_sq);
    var base_charge = 1.0 / ((DT*DT) * Q * (cos_theta/r1_sq +
          cos_phi/r2_sq));

    p.v_x = 0.0;
    p.v_y = p.m/DT;

    p.q = if (x%2 == 0) then (2*p.k+1) * base_charge
      else -1.0 * (2*p.k+1) * base_charge ;
    p.x0 = x_coord;
    p.y0 = y_coord;
  }
}

inline proc computeCoulomb(x_dist, y_dist, q1, q2) {

  const r2 = x_dist**2 + y_dist**2;
  const r = sqrt(r2);
  const f_coulomb = q1*q2/r2;

  const fx = f_coulomb * x_dist/r;
  const fy = f_coulomb * y_dist/r;

  return (fx, fy);
}

proc computeTotalForce(p) {

  const x = floor(p.x):int;
  const y = floor(p.y):int;

  const rel_x = p.x-x;
  const rel_y = p.y-y;

  var tmp_fx = 0.0;
  var tmp_fy = 0.0;

  /*writeln(here, " ", (x,y), " ",*/
      /*Qgrid[x,y].locale, " ",*/
      /*Qgrid[x+1,y].locale, " ",*/
      /*Qgrid[x,y+1].locale, " ",*/
      /*Qgrid[x+1,y+1].locale);*/
  /*(tmp_fx, tmp_fy) = computeCoulomb(rel_x, rel_y, p.q, Qgrid[y,x]);*/
  (tmp_fx, tmp_fy) = computeCoulomb(rel_x, rel_y, p.q, Qgrid[x,y]);
  var tmp_res_x = tmp_fx;
  var tmp_res_y = tmp_fy;

  /*(tmp_fx, tmp_fy) = computeCoulomb(rel_x, 1.0-rel_y, p.q, Qgrid[y+1,x]);*/
  (tmp_fx, tmp_fy) = computeCoulomb(rel_x, 1.0-rel_y, p.q, Qgrid[x+1,y]);
  tmp_res_x += tmp_fx;
  tmp_res_y -= tmp_fy;

  /*(tmp_fx, tmp_fy) = computeCoulomb(1.0-rel_x, rel_y, p.q, Qgrid[y,x+1]);*/
  (tmp_fx, tmp_fy) = computeCoulomb(1.0-rel_x, rel_y, p.q, Qgrid[x,y+1]);
  tmp_res_x -= tmp_fx;
  tmp_res_y += tmp_fy;

  /*(tmp_fx, tmp_fy) = computeCoulomb(1.0-rel_x, 1.0-rel_y, p.q, Qgrid[y+1,x+1]);*/
  (tmp_fx, tmp_fy) = computeCoulomb(1.0-rel_x, 1.0-rel_y, p.q, Qgrid[x+1,y+1]);
  tmp_res_x -= tmp_fx;
  tmp_res_y -= tmp_fy;

  if debug then writeln("Total force on particle : ", (tmp_res_x,
        tmp_res_y));

  return (tmp_res_x, tmp_res_y);
}

proc verifyParticle(p) {

  const y = p.y0:int;
  const x = p.x0:int;

  const disp = (iterations+1):real*(2*p.k+1);
  const x_final = if (p.q * Qgrid[x,y])>0 then p.x0+disp else p.x0-disp;
  const y_final = p.y0 + p.m * (iterations+1):real;

  const x_periodic = mod(x_final+(iterations+1):real *(2*p.k+1)*L, L);
  const y_periodic = mod(y_final+(iterations+1):real *abs(p.m)*L, L);

  if ( abs(p.x - x_periodic) > epsilon || abs(p.y - y_periodic) > epsilon) {
    writeln("Verification for particle failed");
    writeln(p.x, " ", x_periodic);
    writeln(p.y, " ", y_periodic);
    return false;
  }
  return true;
}

inline proc placeParticles(particles, ref pIdx, n, x, y,
    param useAddHere = false) {
  for p in 0..#n {
    if useList {
      var newP = new particle(x=x+REL_X, y=y+REL_Y, k=k, m=m);
      if useAddHere then
        particles.addHere(newP);
      else
        particles.add(newP);
    }
    else {
      particles[pIdx].x = x + REL_X;
      particles[pIdx].y = y + REL_Y;
      particles[pIdx].k = k;
      particles[pIdx].m = m;
    }
    pIdx += 1;
  }
}
