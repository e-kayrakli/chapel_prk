nl=$1
size=$2

./bin/dgemm -nl$nl --order=$size > out/aal_dgemm_base.out
./bin/dgemm_log -nl$nl --order=$size --samplingRate=1.0 > out/aal_dgemm_log_10.out
./bin/dgemm_log -nl$nl --order=$size --samplingRate=0.5 > out/aal_dgemm_log_05.out
./bin/dgemm_log -nl$nl --order=$size --samplingRate=0.1 > out/aal_dgemm_log_01.out
./bin/dgemm_log_stat -nl$nl --order=$size --samplingRate=1.0 > out/aal_dgemm_log_stat_10.out
./bin/dgemm_log_stat -nl$nl --order=$size --samplingRate=0.5 > out/aal_dgemm_log_stat_05.out
./bin/dgemm_log_stat -nl$nl --order=$size --samplingRate=0.1 > out/aal_dgemm_log_stat_01.out


