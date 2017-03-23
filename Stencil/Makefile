SRC=stencil.chpl
MAIN=stencil


include ../Makefile.common

r=1
USERFLAGS=-suseBlockDist -sR=$r

radius_analysis:
	echo Building $@_$r
	chpl $(CHPLFLAGS)\
	$(MISCFLAGS) -o $(BINDIR)/$@_$r stencil_ra.chpl $(USERFLAGS)
