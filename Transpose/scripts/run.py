#! /home/ngnk/builds/env_python2/python
import math

from global_config import *
from util import *
from plot_utils import *

commonflags = "--iterations=2 --tileSize=4"
if use_slurm:
    commonflags = "--iterations=10 --tileSize=8"

if mem_track:
    commonflags = commonflags + " --memTrack"

sdflags = commonflags + " --staticDomain "

versions = [
    VersionType("transpose_base", "0", commonflags, "#ca0020", "o", "solid"),
    VersionType("transpose_handopt", "2", commonflags, "#f4a582", "x", "solid"),
    VersionType("transpose_pref_cons", "3cons", commonflags, "#92c5de", "s", "dashed"),
    VersionType("transpose_pref_incons", "3incons", commonflags, "#0571b0", "x", "dashed"),
    # VersionType("transpose_pref_cons_u", "3cons_u", commonflags, "m", "s", "solid"),
    # VersionType("transpose_pref_incons", "3incons_u", commonflags, "y", "x", "solid"),
    VersionType("transpose_pref_cons", "3cons_sd", sdflags, "#92c5de", "s", "dotted"),
    VersionType("transpose_pref_incons", "3incons_sd", sdflags, "#0571b0", "x", "dotted")]
    # VersionType("transpose_pref_cons_u", "3cons_u_sd", sdflags, "m", "s", "dashed"),
    # VersionType("transpose_pref_incons", "3incons_u_sd", sdflags, "y", "x", "dashed")]

# create weak scaling data size lookup table
for l in locales:
    exact_val = math.sqrt(int(s)**2*int(l)/float(max(locales_int)))
    base = int(l)*4
    if use_slurm:
        base = int(l)*8
    divisible_val=base*(int(exact_val/base)+1)
    ws_sizes[l] = str(int(divisible_val))


if args.mode == 'PLOT':
    create_plots(versions, "prk_transpose")
elif args.mode == 'RUN':
    run_test(versions)
else:
    print("Unknown mode" + args.MODE)

