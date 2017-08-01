#! /usr/bin/env python
import math

from global_config import *
from util import *
from plot_utils import *

commonflags = "--iterations=2 --blockSize=4"
if use_slurm:
    commonflags = "--iterations=10 --blockSize=32"

sdflags = commonflags + " --staticDomain "

versions = [
    VersionType("dgemm_base", "0", commonflags, "#ca0020", "o", "solid"),
    VersionType("dgemm_handopt", "2", commonflags, "#f4a582", "x", "solid"),
    VersionType("dgemm_pref_cons", "3cons", commonflags, "#92c5de", "s", "dashed"),
    VersionType("dgemm_pref_incons", "3incons", commonflags, "#0571b0", "x", "dashed"),
    # VersionType("dgemm_pref_cons_u", "3cons_u", commonflags, "m", "s", "solid"),
    # VersionType("dgemm_pref_incons", "3incons_u", commonflags, "y", "x", "solid"),
    VersionType("dgemm_pref_cons", "3cons_sd", sdflags, "#92c5de", "s", "dotted"),
    VersionType("dgemm_pref_incons", "3incons_sd", sdflags, "#0571b0", "x", "dotted")]
    # VersionType("dgemm_pref_cons_u", "3cons_u_sd", sdflags, "m", "s", "dashed"),
    # VersionType("dgemm_pref_incons", "3incons_u_sd", sdflags, "y", "x", "dashed")]

# create weak scaling data size lookup table
for l in locales:
    ws_sizes[l] = str(int((int(s)**3*int(l)/float(max(locales_int)))**(1./3.)))


if args.mode == 'PLOT':
    create_plots(versions, "prk_dgemm")
elif args.mode == 'RUN':
    run_test(versions)
else:
    print("Unknown mode" + args.MODE)

