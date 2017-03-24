SRC=stencil.chpl
MAIN=stencil


include ../Makefile.common

USERFLAGS=-suseBlockDist

radius_analysis:
	echo Building $@
	chpl $(CHPLFLAGS)\
	$(MISCFLAGS) -o $(BINDIR)/$@ stencil_ra.chpl $(USERFLAGS)
