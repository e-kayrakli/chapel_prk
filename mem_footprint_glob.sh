versions=( 0 2 3cons 3cons_sd 3incons 3incons_sd )

average () {
  cat $1 | tail -n5 | head -n4 | tr -s " "  | cut -d" " -f3 > __tmp
  awk {'a+=$1} END {print a/NR}' __tmp
  rm __tmp
}

cd $1
make cleanout
cd out
tar xzvf *mt*.tar.gz
cd ../../

for v in "${versions[@]}"
do
  average $1/out/*.$v.*out >> tmp_memplot_dump
done
