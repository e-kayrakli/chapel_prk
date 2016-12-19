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

var DomA: domain(1);
