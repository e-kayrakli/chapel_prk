SRC=branch.chpl procs.chpl configs.chpl
MAIN=branch
CHPLFLAGS=--fast --local --vectorize --replace-array-accesses-with-ref-temps
MISCFLAGS=--print-passes --print-commands

all: $(MAIN)

$(MAIN):
	echo Building $@
	chpl --savec c_code $(CHPLFLAGS) $(MISCFLAGS) -o $@ $(SRC) --main-module=$(MAIN)

clean:
	rm -f $(MAIN)
