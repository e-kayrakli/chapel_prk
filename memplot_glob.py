import numpy as np
import matplotlib.pyplot as plt
import os

from collections import namedtuple
from collections import defaultdict

benchmarks = [ "DGEMM" , "Transpose", "Sparse" ]
for b in benchmarks:
    os.system("./mem_footprint_glob.sh " + b)

mem_dict = defaultdict(list)

num_versions = 6
vrange = np.arange(0,6)

rects = []
ind = np.arange(0, len(benchmarks))
width = 0.1

rect = 0.2,0.1,0.7,0.8
fig = plt.figure(figsize=(7,10))
ax = fig.add_axes(rect)

plt.tick_params(axis='x', which='both', bottom='off', top='off',
        labelbottom='off')


VersionType = namedtuple("VersionType", "label color hatch")
versions = [
    VersionType("Base", "#ca0020", ""),
    VersionType("HandOpt", "#f4a582", ""),
    VersionType("AC", "#92c5de", "+"),
    VersionType("MC", "#0571b0", "x"),
    VersionType("AC-SD", "#92c5de", "+"),
    VersionType("MC-SD", "#0571b0", "x")]

max_mem = 0.
with open("tmp_memplot_dump") as f:
  for b in benchmarks:
      for v in versions:
          mem = int(f.readline())
          # mem = (mem[0] / 2**20, )
          if mem > max_mem:
              max_mem = mem
          mem_dict[v].append(mem)

os.system("rm tmp_memplot_dump")

for v in versions:
    print(mem_dict[v])
    rects.append(ax.bar(ind, mem_dict[v], width, edgecolor="k",
                                   label=v.label,
                                   color=v.color,
                                   hatch=v.hatch))
    ind = [i+width for i in ind]


ax.set_ylim((0, max_mem*1.25))
ax.legend(framealpha=1, fontsize=18, ncol=2, loc='upper center')
ax.grid(b=True, axis='y', linestyle='dashed')
ax.set_axisbelow(True)
ax.set_ylabel("Memory Footprint (MB/Locale)")


plt.show()
