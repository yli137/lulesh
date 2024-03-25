#default build suggestion of MPI + OPENMP with gcc on Livermore machines you might have to change the compiler name

SHELL = /bin/sh
.SUFFIXES: .cc .o

LULESH_EXEC = lulesh2.0

MPI_INC = /home/yli137/build/master/include
MPI_LIB = /home/yli137/build/master/lib

SERCXX = g++ -DUSE_MPI=0
MPICXX = mpic++ -DUSE_MPI=1
CXX = $(MPICXX)

SOURCES2.0 = \
	lulesh.cc \
	lulesh-comm.cc \
	lulesh-viz.cc \
	lulesh-util.cc \
	lulesh-init.cc
OBJECTS2.0 = $(SOURCES2.0:.cc=.o)

#Default build suggestions with OpenMP for g++
#CXXFLAGS = -g -O3 -fopenmp -I. -Wall 
#LDFLAGS = -g -O3 -fopenmp -llz4

#Below are reasonable default flags for a serial build
CXXFLAGS = -g -I. -I/apps/spacks/2023-11-15/opt/spack/linux-rocky9-x86_64/gcc-11.3.1/lz4-1.9.4-6twgjmvk4wpygr2nxju2grkwyvmlcqns/include -O3 -Wall
LDFLAGS = -g -O3 -L/apps/spacks/2023-11-15/opt/spack/linux-rocky9-x86_64/gcc-11.3.1/lz4-1.9.4-6twgjmvk4wpygr2nxju2grkwyvmlcqns/lib -llz4 
#CXXFLAGS = -g -I. -Wall
#LDFLAGS = -g -llz4 

#common places you might find silo on the Livermore machines.
#SILO_INCDIR = /opt/local/include
#SILO_LIBDIR = /opt/local/lib
#SILO_INCDIR = ./silo/4.9/1.8.10.1/include
#SILO_LIBDIR = ./silo/4.9/1.8.10.1/lib

#If you do not have silo and visit you can get them at:
#silo:  https://wci.llnl.gov/codes/silo/downloads.html
#visit: https://wci.llnl.gov/codes/visit/download.html

#below is and example of how to make with silo, hdf5 to get vizulization by default all this is turned off.  All paths are Livermore specific.
#CXXFLAGS = -g -DVIZ_MESH -I${SILO_INCDIR} -Wall -Wno-pragmas
#LDFLAGS = -g -L${SILO_LIBDIR} -Wl,-rpath -Wl,${SILO_LIBDIR} -lsiloh5 -lhdf5

.cc.o: lulesh.h
	@echo "Building $<"
	$(CXX) -c $(CXXFLAGS) -o $@  $<

all: $(LULESH_EXEC)

$(LULESH_EXEC): $(OBJECTS2.0)
	@echo "Linking"
	$(CXX) $(OBJECTS2.0) $(LDFLAGS) -lm -o $@

clean:
	/bin/rm -f *.o *~ $(OBJECTS) $(LULESH_EXEC)
	/bin/rm -rf *.dSYM

tar: clean
	cd .. ; tar cvf lulesh-2.0.tar LULESH-2.0 ; mv lulesh-2.0.tar LULESH-2.0

