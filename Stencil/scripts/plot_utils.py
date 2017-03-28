import subprocess
import numpy as np
from collections import defaultdict

from global_config import *
from util import *

def parse(versions):
    ss_means = defaultdict(list)
    ss_stddevs = defaultdict(list)
    for v in versions:
        for l in locales:
            ss_try_list = []
            for t in tries:
                # strong scaling
                grep_cmd = get_time_extract_cmd(v,s,l,t)
                print(grep_cmd)
                output = subprocess.check_output(
                            grep_cmd,
                            shell=True)
                ss_try_list.append(float(output))
                # weak scaling
            ss_means[v.abbrev].append(np.mean(ss_try_list))
            ss_stddevs[v.abbrev].append(np.std(ss_try_list))
    return ss_means

def create_plots(versions, plot_name_prefix):
    import matplotlib.pyplot as plt
    datasets = parse(versions)

    rect = 0.1,0.1,0.8,0.8

    # for r in radii:
        # print(datasets["R"+r+"nopref"])
    # print
    # for r in radii:
        # print(datasets["R"+r+"pref"])

    improv = []
    for r in radii:
        # print(datasets["R"+r+"nopref"][0]/datasets["R"+r+"pref"][0])
        improv.append(datasets["R"+r+"nopref"][0]/datasets["R"+r+"pref"][0])

    improv = []
    for r in radii:
        # print(datasets["R"+r+"nopref"][0]/datasets["R"+r+"pref"][0])
        improv.append(datasets["R"+r+"nopref"][0]/datasets["R"+r+"pref"][0])
    # print(improv)

    improv_incons = []
    for r in radii:
        improv_incons.append(datasets["R"+r+"nopref"][0]/datasets["R"+r+"pref_incons"][0])

    flt_radii = [float(r) for r in radii]
    # ratios = [sum(range(max(1,2*int(r)-int(s)/2+1),int(r)+1))/((4*float(s)*r+float(s)-8*r**2-2*r)/2) for r in flt_radii]
    ratios = [(int(s)-2*r)*((6*r-float(s)+2)/8)/((4*float(s)*r+float(s)-8*r**2-2*r)/2) for r in flt_radii]
    print(ratios)

    filename = (plot_path + "/" +
            plot_name_prefix)
    d_fig = plt.figure(figsize=(10,10))
    d_ax = d_fig.add_axes(rect)
    d_ax_right = d_ax.twinx()

    max_y = max(max(improv), max(improv_incons))

    d_ax.plot([int(r) for r in radii], improv, label='Improvement')
    d_ax.plot([int(r) for r in radii], improv_incons, label='Incons Improvement')
    d_ax_right.plot([int(r) for r in radii], ratios, label='Ratios')

    #legend
    d_ax.legend(loc=0, fontsize=12)
    #grid
    d_ax.grid(b=True, axis='x')
    # x axis settings
    d_ax.set_xlabel("Stencil Radius")
    d_ax.set_xticks([int(r) for r in radii])
    # d_ax.set_xlim((0,510))
    # y axis settings
    d_ax.set_ylabel("Ratio")
    d_ax.set_ylim((0,max_y*1.1))
    # d_ax_right.set_ylim((-0.05,0.3))
    print("Plot saved: " + filename)
    plt.savefig(filename)
    plt.close()
