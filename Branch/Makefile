SRC=branch.chpl procs.chpl configs.chpl
MAIN=branch
CHPLFLAGS=--fast --local --vectorize
MISCFLAGS=--print-passes --print-commands

all: $(MAIN)

$(MAIN):
	echo Building $(MAIN)
	chpl $(CHPLFLAGS) $(MISCFLAGS) -o $(MAIN) $(SRC) --main-module=$(MAIN)

clean:
	rm -f $(MAIN)
