import subprocess
import numpy as np
from collections import defaultdict

from global_config import *
from util import *

nice_labels = { '0'     : 'Base',
                '2'     : 'HandOpt',
                '3cons'     : 'AC-Serial',
                '3cons_u'     : 'AC-Deserial',
                '3cons_u_sd'     : 'AC-Deserial-SD',
                '3cons_sd'     : 'AC-Serial-SD',
                '3incons'     : 'MC-Serial',
                '3incons_u'     : 'MC-Deserial',
                '3incons_u_sd'     : 'MC-Deserial-SD',
                '3incons_sd'     : 'MC-Serial-SD'}

def parse(versions):
    ss_means = defaultdict(list)
    ss_stddevs = defaultdict(list)
    ws_means = defaultdict(list)
    ws_stddevs = defaultdict(list)
    for v in versions:
        for l in locales:
            ss_try_list = []
            ws_try_list = []
            for t in tries:
                # strong scaling
                grep_cmd = get_time_extract_cmd(v,s,l,t)
                print(grep_cmd)
                output = subprocess.check_output(
                            grep_cmd,
                            shell=True)
                ss_try_list.append(float(output))
                # weak scaling
                if not no_ws:
                    grep_cmd = get_time_extract_cmd(v, get_ws_size(s,l),l,t)
                    print(grep_cmd)
                    output = subprocess.check_output(
                                grep_cmd,
                                shell=True)
                    ws_try_list.append(float(output))
            ss_means[v.abbrev].append(np.mean(ss_try_list))
            ss_stddevs[v.abbrev].append(np.std(ss_try_list))
            ws_means[v.abbrev].append(np.mean(ws_try_list))
            ws_stddevs[v.abbrev].append(np.std(ws_try_list))
    # return(ss_means, ss_stddevs, ws_means, ws_stddevs)
    return(ss_means, ws_means)

def create_plots(versions, plot_name_prefix):
    do_create_plots(versions, plot_name_prefix, True)
    do_create_plots(versions, plot_name_prefix, False)

def do_create_plots(versions, plot_name_prefix, do_imp_plot):
    import matplotlib as mpl
    import matplotlib.pyplot as plt
    import matplotlib.lines as ll

    mpl.rcParams['lines.markersize'] = 12
    mpl.rcParams['lines.linewidth'] = 3
    datasets = parse(versions)

    rect = 0.1,0.1,0.8,0.8
    suffixes = ["_ss", "_ws"]
    if no_ws:
        datasets = [datasets[0]]
        suffixes = [suffixes[0]]
    for d,suffix in zip(datasets, suffixes):
    # d = datasets[0]
    # suffix = "_ss"
        filename = (plot_path + plot_name_prefix + "/" +
            plot_name_prefix + suffix + "_" + args.host + "_" +
            s + "_" + str(args.num_tries))
        if do_imp_plot:
            filename = filename+"_imp"
        d_fig = plt.figure(figsize=(10,6))
        d_ax = d_fig.add_axes(rect)
        max_y = 0
         # fake white line for legend adjustment
        l = ll.Line2D([0],[0],color="w")

        lines = []
        labels = []
        fake_line_added = False
        for v in versions:
            if do_imp_plot:
                lines.append(d_ax.plot(locales_int,
                    [base/self for (self,base) in zip(d[v.abbrev], d["0"])],
                    label=nice_labels[v.abbrev], color=v.color, marker=v.marker,
                    linestyle=v.linestyle)[0])
            else:
                lines.append(d_ax.plot(locales_int, d[v.abbrev],
                        label=nice_labels[v.abbrev], color=v.color, marker=v.marker,
                        linestyle=v.linestyle, markerfacecolor='none',
                        markeredgewidth=2)[0])
            if max(d[v.abbrev]) > max_y:
                max_y = max(d[v.abbrev])
            labels.append(nice_labels[v.abbrev])
            if not fake_line_added:
                lines.append(l)
                labels.append("")
                fake_line_added = True

        #legend
        if do_legend:
            d_ax.legend(tuple(lines), labels, loc='best', fontsize=22,
                    fancybox=False, ncol=3, bbox_to_anchor=(0.5,1.05))
        #grid
        d_ax.grid(b=True, axis='x')
        d_ax.grid(b=True, axis='y', linestyle='dashed')

        #adjust borders
        d_ax.spines['top'].set_linewidth(1)
        d_ax.spines['bottom'].set_linewidth(1)
        d_ax.spines['left'].set_linewidth(1)
        d_ax.spines['right'].set_linewidth(1)

        # x axis settings
        d_ax.set_xlabel("Locales")
        d_ax.set_xticks(locales_int)
        if square_locales:
            d_ax.set_xlim((0,38))
        else:
            d_ax.set_xlim((0,35))
        # y axis settings
        if do_imp_plot:
            d_ax.set_ylabel("Speedup Over Base")
        else:
            d_ax.set_ylabel("Time (s)")
        if log_scale:
            d_ax.set_yscale('log')
        print("Plot saved: " + filename)
        plt.savefig(filename)
        plt.close()
