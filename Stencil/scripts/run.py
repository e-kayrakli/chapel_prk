#! /home/ngnk/builds/env_python2/python
import math

from global_config import *
from util import *
from plot_utils import *

commonflags = " --iterations=10 "
prefflags = commonflags + " --prefetch  --staticDomain "

versions = []
for r in radii:
    versions.append(
            VersionType("radius_analysis", "R"+r+"nopref",
                commonflags+"--R="+r))
for r in radii:
    versions.append(
            VersionType("radius_analysis", "R"+r+"pref",
                prefflags+"--R="+r))

for r in radii:
    versions.append(
            VersionType("radius_analysis", "R"+r+"pref_incons",
                prefflags+"--R="+r+" --consistent=false"))

# create weak scaling data size lookup table
for l in locales:
    ws_sizes[l] = str(int(math.sqrt(int(s)**2*int(l)/float(max(locales_int)))))


if args.mode == 'PLOT':
    create_plots(versions, "radius_analysis")
elif args.mode == 'RUN':
    run_test(versions)
else:
    print("Unknown mode" + args.MODE)

