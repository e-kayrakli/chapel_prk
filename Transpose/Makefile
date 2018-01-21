CHPL=chpl
CHPL_FLAGS=--fast

all: transpose transpose_log transpose_log_stat

transpose: transpose.chpl
	$(CHPL) $(CHPLFLAGS) -o ./bin/$@ $^

transpose_log: transpose.chpl
	$(CHPL) $(CHPLFLAGS) -senableAccessLogs=true -o ./bin/$@ $^

transpose_log_stat: transpose.chpl
	$(CHPL) $(CHPLFLAGS) -senableAccessLogs=true -o ./bin/$@ $^ --ccflags -DGENERATE_COMPRESSION_STATS

cleanout:
	rm -f {err,out}/transpose*

clean:
	rm -f {bin,err,out}/transpose* 

