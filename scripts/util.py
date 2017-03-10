import os
from global_config import *
from collections import namedtuple

ws_sizes = {}

VersionType = namedtuple("VersionType", "execname abbrev flags color marker")

def get_name(v, l, s, t):
    return v.execname + "." + v.abbrev + "." + l + "." + s + ".try" + str(t)

def get_time_extract_cmd(v,s,l,t):
    return ("grep -m 1 Rate ./out/"+ get_name(v,l,s,t)+".out | cut -d\" \" -f3")

# version(opt) name, version flags, size, numlocales
# def get_run_cmd(v_name, v_flags,s,l,t):
def get_run_cmd(v,s,l,t):
    if use_slurm:
        return ("./bin/"+v.execname+
                " -nl"      +l+
                " --order="     +s+
                " "         +v.flags)
    else:
        return ("./bin/"+v.execname+
                " -nl"      +l+
                " --order="     +s+
                " "         +v.flags+
                " > ./out/" +get_name(v,l,s,t))+".out"

def runcommand(command):
    print(command)
    os.system(command)

def get_cmd(v,s,l,t):
    if use_slurm:
        return get_slurm_cmd(v,s,l,t)
    else:
        return get_run_cmd(v,s,l,t)

def get_slurm_cmd(v,s,l,t):
    name = get_name(v,l,s,t)
    runcommand("echo -e \'#!/bin/sh\\n" + get_run_cmd(v,s,l,t) +
          "\' > ./scripts/__batch."+get_name(v,l,s,t))
    return ("sbatch"+
                    " -N" + l +
                    " --output=./out/" + name + ".out" +
                    " --error=./err/" + name + ".err" +
                    " --partition=" + slurm_part +
                    " --job-name=" + name +
                    " ./scripts/__batch."+get_name(v,l,s,t))

def get_ws_size(base_size, num_locales):
    return ws_sizes[num_locales];

def run_test(versions):
    for v in versions:
        for l in locales:
            for t in tries:
                # strong scaling
                runcommand(get_cmd(v,s,l,t))
                # weak scaling
                runcommand(get_cmd(v,get_ws_size(s,l),l,t))
    runcommand("make cleanslurm")

