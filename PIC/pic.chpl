use Time;

extern proc LCG_init();
extern proc random_draw(x: c_double): uint(64);

param REL_X = 0.5;
param REL_Y = 0.5;
param DT = 1.0;
param Q = 1.0;
param MASS_INV = 1.0;
param epsilon = 0.000001;

config const L = 10; // grid size
config var n = 10; // particles requested
config const k = 1;
config const m = 1;
config const iterations = 10;
config const debug = false;
config const particleMode = "SINUSOIDAL";

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

config const initPatchLeft = 1;
config const initPatchRight = 2;
config const initPatchTop= 1;
config const initPatchBottom = 2;

const initPatch = new bbox(initPatchLeft,
                           initPatchRight,
                           initPatchTop,
                           initPatchBottom);

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

var Qgrid = initializeGrid(L);

var particleDom = {1..0};
var particles: [particleDom] particle;

select particleMode {
  when "GEOMETRIC" do
    particles = initializeGeometric(n, L, rho, k, m, n);
  when "SINUSOIDAL" do
    particles = initializeSinusoidal(n, L, k, m, n);
  when "LINEAR" do
    particles = initializeLinear(n, L, alpha, beta, k, m, n);
  when "PATCH" {
    if badPatch(initPatch, gridPatch) then
      halt("Bad patch given");
    particles = initializePatch(n, L, initPatch, k, m, n);
  }
  otherwise do
    halt("Unknown particle mode: ", particleMode);
}

writeln("Number of particles placed : ", n);

const t = new Timer();

for niter in 0..iterations {

  if niter == 1 then t.start();

  forall i in 0..#n {
    var fx = 0.0;
    var fy = 0.0;


    computeTotalForce(particles[i], L, Qgrid, fx, fy);
    if debug then writeln("Force acting on particle " , i, " ", (fx,fy));
    const ax = fx * MASS_INV;
    const ay = fy * MASS_INV;

    if debug then write("Particle ", i, " moved from ",
        (particles[i].x,particles[i].y));

    particles[i].x = mod(particles[i].x + particles[i].v_x*DT + 0.5*ax*DT*DT + L, L);
    particles[i].y = mod(particles[i].y + particles[i].v_y*DT + 0.5*ay*DT*DT + L, L);

    if debug then writeln(" to ",
        (particles[i].x,particles[i].y));

    particles[i].v_x += ax * DT;
    particles[i].v_y += ay * DT;
  }
}
t.stop();


for i in 0..#n {
  if !verifyParticle(particles[i], iterations, Qgrid, L) then
    halt("Verification failed");
}

writeln("Verification succesful");

const avgTime = t.elapsed()/iterations;
writeln("Rate (Mparticles_moved/s): ", 1.0e-6*(n/avgTime));

proc initializeGrid(L) {
  const gridDom = {0..#(L+1), 0..#(L+1)};
  var grid: [gridDom] real;

  for (x,y) in grid.domain {
    grid[y,x] = if x%2==0 then Q else -Q;
  }
  return grid;
}

proc initializeGeometric(n_input, L, rho, k, m, ref n_placed) {

  LCG_init();

  var A = n_input * ((1.0-rho) / (1.0-(rho**L))) / L:real;

  n_placed = 0;
  for x in 0..#L {
    for y in 0..#L {
      n_placed += random_draw(A*(rho**x)):int;
    }
  }

  particleDom = {0..#n_placed};

  LCG_init();

  A = n_input * ((1.0-rho) / (1.0-(rho**L))) / L:real;
  var pIdx = 0;
  for x in 0..#L {
    for y in 0..#L {
      // TODO without cast this creates a seg fault and overflow
      // warning with no --fast. Investigate for possible bug. Engin
      const actual_particles = random_draw(A * (rho**x)):int;
      for p in 0..#actual_particles {
        particles[pIdx].x = x + REL_X;
        particles[pIdx].y = y + REL_Y;
        particles[pIdx].k = k;
        particles[pIdx].m = m;
        pIdx += 1;
      }
    }
  }

  finish_distribution(n_placed, particles);
  return particles;
}

proc initializeSinusoidal(n_input, L, k, m,
    ref n_placed) {

  const step = pi/L;

  LCG_init();

  n_placed = 0;

  for x in 0..#L {
    for y in 0..#L {
      n_placed +=
        random_draw(2.0*cos(x*step)*cos(x*step)*n_input/(L*L)):int;
    }
  }

  particleDom = {0..#n_placed};

  LCG_init();

  // pIdx = pi in OpenMP code
  var pIdx = 0;
  for x in 0..#L {
    for y in 0..#L {
      // TODO without cast this creates a seg fault and overflow
      // warning with no --fast. Investigate for possible bug. Engin
      const actual_particles =
        random_draw(2.0*cos(x*step)*cos(x*step)*n_input/(L*L)):int;
      for p in 0..#actual_particles {
        particles[pIdx].x = x + REL_X;
        particles[pIdx].y = y + REL_Y;
        particles[pIdx].k = k;
        particles[pIdx].m = m;
        pIdx += 1;
      }
    }
  }

  finish_distribution(n_placed, particles);
  return particles;
}

proc initializeLinear(n_input, L, alpha, beta, k, m, ref n_placed) {

  const step = 1.0/L;
  n_placed = 0;

  LCG_init();

  const total_weight = beta*L-alpha*0.5*step*L*(L-1);
  for x in 0..#L {
    const current_weight = (beta - alpha * step * x:real);
    for y in 0..#L {
      n_placed +=
        random_draw(n_input * (current_weight/total_weight)/L):int;
    }
  }

  particleDom = {0..#n_placed};

  LCG_init();

  var pIdx = 0;
  for x in 0..#L {
    const current_weight = (beta - alpha * step * x:real);
    for y in 0..#L {
      // TODO without cast this creates a seg fault and overflow
      // warning with no --fast. Investigate for possible bug. Engin
      const actual_particles =
        random_draw(n_input * (current_weight/total_weight)/L):int;
      for p in 0..#actual_particles {
        particles[pIdx].x = x + REL_X;
        particles[pIdx].y = y + REL_Y;
        particles[pIdx].k = k;
        particles[pIdx].m = m;
        pIdx += 1;
      }
    }
  }
  finish_distribution(n_placed, particles);
  return particles;
}

proc initializePatch(n_input, L, patch, k, m, ref n_placed) {
  n_placed = 0;
  LCG_init();

  const total_cells  = (patch.right - patch.left+1)*(patch.top -
      patch.bottom+1);
  const particles_per_cell = (n_input/total_cells):real;
  for x in 0..#L {
    for y in 0..#L {
      var actual_particles = random_draw(particles_per_cell):int;
      if x<patch.left   || x>patch.right ||
         y<patch.bottom || y>patch.top then
        actual_particles = 0;
      n_placed += actual_particles;
    }
  }

  particleDom = {0..#n_placed};
  var pIdx = 0;
  for x in 0..#L {
    for y in 0..#L {
      // TODO without cast this creates a seg fault and overflow
      // warning with no --fast. Investigate for possible bug. Engin
      var actual_particles = random_draw(particles_per_cell):int;
      if x<patch.left   || x>patch.right ||
         y<patch.bottom || y>patch.top then
        actual_particles = 0;
      for p in 0..#actual_particles {
        particles[pIdx].x = x + REL_X;
        particles[pIdx].y = y + REL_Y;
        particles[pIdx].k = k;
        particles[pIdx].m = m;
        pIdx += 1;
      }
    }
  }
  finish_distribution(n_placed, particles);
  return particles;
}

proc finish_distribution(n, p) { //n is the size, unnecessary
  for pIdx in 0..#n {
    var x_coord = p[pIdx].x;
    var y_coord = p[pIdx].y;
    var rel_x = mod(x_coord, 1.0);
    var rel_y = mod(y_coord, 1.0);

    var x = x_coord:uint;
    var r1_sq = rel_y * rel_y + rel_x * rel_x;
    var r2_sq = rel_y * rel_y + (1.0-rel_x) * (1.0-rel_x);
    var cos_theta = rel_x/sqrt(r1_sq);
    var cos_phi = (1.0-rel_x)/sqrt(r2_sq);
    var base_charge = 1.0 / ((DT*DT) * Q * (cos_theta/r1_sq +
          cos_phi/r2_sq));

    p[pIdx].v_x = 0.0;
    p[pIdx].v_y = p[pIdx].m/DT;

    p[pIdx].q = if (x%2 == 0) then (2*p[pIdx].k+1) * base_charge
      else -1.0 * (2*p[pIdx].k+1) * base_charge ;
    p[pIdx].x0 = x_coord;
    p[pIdx].y0 = y_coord;
  }
}

proc computeCoulomb(x_dist, y_dist, q1, q2, ref fx, ref fy) {

  const r2 = x_dist**2 + y_dist**2;
  const r = sqrt(r2);
  const f_coulomb = q1*q2/r2;

  fx = f_coulomb * x_dist/r;
  fy = f_coulomb * y_dist/r;

  if debug then writeln("Coulomb force : ", (fx, fy));
}

proc computeTotalForce(p, L, Qgrid, ref fx, ref fy) {

  const y = floor(p.y):int;
  const x = floor(p.x):int;

  const rel_x = p.x-x;
  const rel_y = p.y-y;

  if debug then writeln("rel_xy ", (rel_x, rel_y));

  var tmp_fx = 0.0;
  var tmp_fy = 0.0;

  computeCoulomb(rel_x, rel_y, p.q, Qgrid[y,x], tmp_fx, tmp_fy);
  var tmp_res_x = tmp_fx;
  var tmp_res_y = tmp_fy;

  computeCoulomb(rel_x, 1.0-rel_y, p.q, Qgrid[y+1,x], tmp_fx, tmp_fy);
  tmp_res_x += tmp_fx;
  tmp_res_y -= tmp_fy;

  computeCoulomb(1.0-rel_x, rel_y, p.q, Qgrid[y,x+1], tmp_fx, tmp_fy);
  tmp_res_x -= tmp_fx;
  tmp_res_y += tmp_fy;

  computeCoulomb(1.0-rel_x, 1.0-rel_y, p.q, Qgrid[y+1,x+1], tmp_fx, tmp_fy);
  tmp_res_x -= tmp_fx;
  tmp_res_y -= tmp_fy;

  fx = tmp_res_x;
  fy = tmp_res_y;

  if debug then writeln("Total force on particle : ", (fx, fy));
}

proc verifyParticle(p, iterations, Qgrid, L) {

  const y = p.y0:int;
  const x = p.x0:int;

  const disp = (iterations+1):real*(2*p.k+1);
  const x_final = if (p.q * Qgrid[y,x])>0 then p.x0+disp else p.x0-disp;
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
