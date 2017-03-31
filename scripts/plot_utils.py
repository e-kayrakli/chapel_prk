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
    import matplotlib.pyplot as plt
    datasets = parse(versions)

    rect = 0.1,0.1,0.8,0.8
    for d,suffix in zip(datasets, ["_ss", "_ws"]):
        filename = (plot_path + plot_name_prefix + "/" +
            plot_name_prefix + suffix + "_" + args.host + "_" +
            s + "_" + str(args.num_tries))
        if do_imp_plot:
            filename = filename+"_imp"
        d_fig = plt.figure(figsize=(10,10))
        d_ax = d_fig.add_axes(rect)
        max_y = 0
        for v in versions:
            if do_imp_plot:
                d_ax.plot(locales_int,
                    [base/self for (self,base) in zip(d[v.abbrev], d["0"])],
                    label=nice_labels[v.abbrev], color=v.color, marker=v.marker,
                    linestyle=v.linestyle)
            else:
                d_ax.plot(locales_int, d[v.abbrev],
                        label=nice_labels[v.abbrev], color=v.color, marker=v.marker,
                        linestyle=v.linestyle)
            if max(d[v.abbrev]) > max_y:
                max_y = max(d[v.abbrev])

        #legend
        if do_legend:
            d_ax.legend(loc=0, fontsize=12)
        #grid
        d_ax.grid(b=True, axis='x')
        # x axis settings
        d_ax.set_xlabel("Number of Locales")
        d_ax.set_xticks(locales_int)
        if square_locales:
            d_ax.set_xlim((0,50))
        else:
            d_ax.set_xlim((0,35))
        # y axis settings
        if do_imp_plot:
            d_ax.set_ylabel("Speedup Over Base")
        else:
            d_ax.set_ylabel("Execution Time (s)")
        if log_scale:
            d_ax.set_yscale('log')
        print("Plot saved: " + filename)
        plt.savefig(filename)
        plt.close()
