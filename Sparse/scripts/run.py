#! /home/ngnk/builds/env_python2/python
import math

from global_config import *
from util import *
from plot_utils import *

commonflags = " --iterations=2 "
if use_slurm:
    commonflags = " --iterations=10 "

versions = [
    VersionType("sparse_base", "0", commonflags, "b", "o", "solid"),
    VersionType("sparse_pref_cons", "3cons", commonflags, "r", "^", "solid"),
    VersionType("sparse_pref_incons", "3incons", commonflags, "c", "8", "solid"),
    VersionType("sparse_pref_cons_u", "3cons_u", commonflags, "m", "s", "solid"),
    VersionType("sparse_pref_incons", "3incons_u", commonflags, "y", "x", "solid"),
    VersionType("sparse_pref_cons", "3cons_sd", commonflags, "r", "^", "dashed"),
    VersionType("sparse_pref_incons", "3incons_sd", commonflags, "c", "8", "dashed"),
    VersionType("sparse_pref_cons_u", "3cons_u_sd", commonflags, "m", "s", "dashed"),
    VersionType("sparse_pref_incons", "3incons_u_sd", commonflags, "y", "x", "dashed")]

# create weak scaling data size lookup table
for l in locales:
    ws_sizes[l] = str(int(math.sqrt(int(s)**2*int(l)/float(max(locales_int)))))


if args.mode == 'PLOT':
    create_plots(versions, "prk_sparse")
elif args.mode == 'RUN':
    run_test(versions)
else:
    print("Unknown mode" + args.MODE)

