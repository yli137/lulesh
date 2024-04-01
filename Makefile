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
	lulesh-init.cc \
	lulesh-compression.cc
OBJECTS2.0 = $(SOURCES2.0:.cc=.o)

CXXFLAGS = -g -I. -O3 -Wall -lpthread
LDFLAGS = -g -O3 -llz4 -lpthread

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

