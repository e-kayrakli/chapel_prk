#! /home/ngnk/builds/env_python2/python
import math

from global_config import *
from util import *
from plot_utils import *

commonflags = "--iterations=10"
prefflags = commonflags + " --prefetch --consistent --staticDomain "

versions = []
for r in radii:
    versions.append(
            VersionType("radius_analysis_"+r, "R"+r+"nopref",
                commonflags))
for r in radii:
    versions.append(
            VersionType("radius_analysis_"+r, "R"+r+"pref",
                prefflags))

# create weak scaling data size lookup table
for l in locales:
    ws_sizes[l] = str(int(math.sqrt(int(s)**2*int(l)/float(max(locales_int)))))


if args.mode == 'PLOT':
    create_plots(versions, "radius_analysis")
elif args.mode == 'RUN':
    run_test(versions)
else:
    print("Unknown mode" + args.MODE)

