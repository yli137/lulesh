SHELL = /bin/sh

LULESH_EXEC = lulesh2.0

MPI_INC = /opt/local/include/openmpi
MPI_LIB = /opt/local/lib

MPICXX = mpic++ -DUSE_MPI=1
CXX = $(MPICXX)

SOURCES2.0 = \
	lulesh.cc \
	lulesh-comm.cc \
	lulesh-viz.cc \
	lulesh-util.cc \
	lulesh-init.cc
OBJECTS2.0 = $(SOURCES2.0:.cc=.o)

CXXFLAGS = -g -I. -I/apps/spacks/2023-11-15/opt/spack/linux-rocky9-x86_64/gcc-11.3.1/lz4-1.9.4-6twgjmvk4wpygr2nxju2grkwyvmlcqns/include -O3 -Wall -pthread
LDFLAGS = -g -O3 -L/apps/spacks/2023-11-15/opt/spack/linux-rocky9-x86_64/gcc-11.3.1/lz4-1.9.4-6twgjmvk4wpygr2nxju2grkwyvmlcqns/lib -llz4 -pthread

#.cc.o: lulesh.h
#	$(CXX) -c $(CXXFLAGS) -o $@  $<
%.o: %.cc lulesh.h
	$(CXX) -c $(CXXFLAGS) -o $@  $<

all: $(LULESH_EXEC)

$(LULESH_EXEC): $(OBJECTS2.0)
	$(CXX) $(OBJECTS2.0) $(LDFLAGS) -lm -o $@

clean:
	/bin/rm -f *.o *~ $(OBJECTS) $(LULESH_EXEC)
	/bin/rm -rf *.dSYM

tar: clean
	cd .. ; tar cvf lulesh-2.0.tar LULESH-2.0 ; mv lulesh-2.0.tar LULESH-2.0

