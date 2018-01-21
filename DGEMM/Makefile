CHPL=chpl
CHPL_FLAGS=--fast

all: dgemm dgemm_log dgemm_log_stat

dgemm: dgemm.chpl
	$(CHPL) $(CHPLFLAGS) -o ./bin/$@ $^

dgemm_log: dgemm.chpl
	$(CHPL) $(CHPLFLAGS) -senableAccessLogs=true -o ./bin/$@ $^

dgemm_log_stat: dgemm.chpl
	$(CHPL) $(CHPLFLAGS) -senableAccessLogs=true -o ./bin/$@ $^ --ccflags -DGENERATE_COMPRESSION_STATS

cleanout:
	rm -f {err,out}/dgemm*

clean:
	rm -f {bin,err,out}/dgemm* 

