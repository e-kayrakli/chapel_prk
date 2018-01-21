nl=$1
size=$2

./bin/transpose -nl$nl --order=$size > out/aal_transpose_base.out
./bin/transpose_log -nl$nl --order=$size --samplingRate=1.0 > out/aal_transpose_log_10.out
./bin/transpose_log -nl$nl --order=$size --samplingRate=0.5 > out/aal_transpose_log_05.out
./bin/transpose_log -nl$nl --order=$size --samplingRate=0.1 > out/aal_transpose_log_01.out
./bin/transpose_log_stat -nl$nl --order=$size --samplingRate=1.0 > out/aal_transpose_log_stat_10.out
./bin/transpose_log_stat -nl$nl --order=$size --samplingRate=0.5 > out/aal_transpose_log_stat_05.out
./bin/transpose_log_stat -nl$nl --order=$size --samplingRate=0.1 > out/aal_transpose_log_stat_01.out


