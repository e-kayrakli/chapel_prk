import argparse

# plot_path = '/home/ngnk/papers/prefetch_v2/plots/'
plot_path = '/home/ngnk/'
parser = argparse.ArgumentParser()

parser.add_argument("--slurm", action="store_true")
parser.add_argument("mode", choices=['RUN', 'PLOT'])
parser.add_argument("size")
parser.add_argument("num_tries", type=int, default=5)

args = parser.parse_args()
s=args.size
control_s = int(s) # make sure its actually an int

# these two can also be an argument
use_slurm = args.slurm
slurm_part = "all" # no effect if !use_slurm. george:hpcl, pyramid:all

locales=["01", "02" , "04"]
locales_int = [1,2,4]

if use_slurm:
    # locales=["01", "02" , "04", "08", "16", "32"]
    # locales_int = [1,2,4,8,16,32]
    locales=["01", "04", "09", "16", "25"]
    locales_int = [1,4,9,16,25]

tries = range(1, args.num_tries+1)
