param PRKVERSION = "2.15";

config const numTasks = here.maxTaskPar;
config const iterations : int = 100,
             length : int = 1000,
             branchType : string = "vector_stop",
             debug: bool = false,
             validate: bool = false;

type dataType = int(32);
config var tileSize: int = 0;

/* the following values are only used as labels */
const WITH_BRANCHES = true;
const WITHOUT_BRANCHES = false;
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
