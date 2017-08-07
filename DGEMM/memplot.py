import numpy as np
import matplotlib.pyplot as plt

num_versions = 6
vrange = np.arange(0,4)

rects = []
ind = 0
width = 0.1

fig, ax = plt.subplots()

with open("tmp_memplot_dump") as f:
  for v in vrange:
      mem = (int(f.readline()), )
      print(ind)
      rects.append(ax.bar(ind, mem, width))
      ind += width


plt.show()
