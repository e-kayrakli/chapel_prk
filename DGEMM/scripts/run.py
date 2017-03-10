#! /home/ngnk/builds/env_python2/python
import math

from global_config import *
from util import *
from plot_utils import *

commonflags = "--iterations=2 --blockSize=4"
versions = [
    VersionType("dgemm_base", "0", commonflags, "b", "o"),
    VersionType("dgemm_pref_cons", "3cons", commonflags, "r", "^"),
    VersionType("dgemm_pref_incons", "3incons", commonflags, "c", "8"),
    VersionType("dgemm_pref_cons_u", "3cons_u", commonflags, "m", "s"),
    VersionType("dgemm_pref_incons", "3incons_u", commonflags, "y", "x")]

# create weak scaling data size lookup table
for l in locales:
    ws_sizes[l] = str(int(math.sqrt(int(s)**2*int(l)/float(max(locales_int)))))


if args.mode == 'PLOT':
    create_plots(versions, "dgemm")
elif args.mode == 'RUN':
    run_test(versions)
else:
    print("Unknown mode" + args.MODE)

