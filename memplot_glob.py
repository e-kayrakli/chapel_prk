import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import os

from collections import namedtuple
from collections import defaultdict

# mpl.rcParams['hatch.linewidth'] = 3.0

os.system("rm -f tmp_memplot_dump")
benchmarks = [ "DGEMM" , "Transpose", "Sparse", "DGEMM", "Transpose" ]
for b in benchmarks:
    os.system("./mem_footprint_glob.sh " + b)

mem_dict = defaultdict(list)

rects = []
ind = np.arange(0, len(benchmarks)*1.2, 1.2)
width = 0.125

rect = 0.1,0.12,0.85,0.8
fig = plt.figure(figsize=(13,5))
ax = fig.add_axes(rect)

plt.tick_params(axis='x', which='both', bottom='off', top='off')

VersionType = namedtuple("VersionType", "label color hatch")
versions = [
    VersionType("Base", "#ca0020", ""),
    VersionType("HandOpt", "#f4a582", ""),
    VersionType("AC", "#92c5de", ""),
    VersionType("AC-SD", "#92c5de", "xxxxx+++++"),
    VersionType("MC", "#0571b0", ""),
    VersionType("MC-SD", "#0571b0", "xxxxx+++++")]

with open("tmp_memplot_dump") as f:
  for b in benchmarks:
      for v in versions:
          mem = int(f.readline())
          mem_dict[v].append(mem)

os.system("rm tmp_memplot_dump")

# normalize footprints and find the max
max_mem = 0.
base_mem_list = mem_dict[versions[0]]
for v in versions:
    mem_dict[v] = [mem/base for mem,base in zip(mem_dict[v], base_mem_list)]
    tmp_max = max(mem_dict[v])
    if tmp_max > max_mem:
        max_mem = tmp_max

# plot bars
count = 0
pad = 0.04
pad_cur = 0.
for v in versions:
    rects.append(ax.bar([i+count*width+pad_cur for i in ind],
                     mem_dict[v], width, 
                     linewidth=2, edgecolor="k",
                                   label=v.label,
                                   color=v.color,
                                   hatch=v.hatch))
    count += 1
    if count == 2:
        pad_cur = pad

adj_fontsize=17
ax.set_ylim((0, max_mem*1.45))
ax.legend(framealpha=1, fontsize=adj_fontsize, ncol=3, loc='upper center')
ax.grid(b=True, axis='y', linestyle='dashed')
ax.set_axisbelow(True)
ax.set_ylabel("Normalized Memory Footprint", fontsize=adj_fontsize)
ax.set_yticklabels((0,2,4,6), fontsize=adj_fontsize)

ax.set_xticks([i+(width*len(versions))/2-width/2+pad/2 for i in ind])
ax.set_xticklabels(tuple(benchmarks), fontsize=adj_fontsize)


filename='/home/ngnk/papers/prefetch_v3/plots_new/mem_footprint'
plt.savefig(filename)  # just as an alternative
plt.savefig(filename+".eps", format='eps', dpi=1000) 
