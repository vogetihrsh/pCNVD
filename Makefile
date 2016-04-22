# MAKE FILE FOR PAIRED END METHOD 
#

CC=$(CXX)
MCXX=mpic++
CFLAGS= -g

CAL=calAvg
SEGMENT=segment

all: $(CAL) $(SEGMENT)

$(SEGMENT): source/segment.cpp
	    $(MCXX) -o $(SEGMENT) source/segment.cpp
$(CAL): source/calculate.cpp 
	$(CC) $(CFLAGS) -o $(CAL) source/calculate.cpp 

clean: 
	$(RM) $(CAL) $(SEGMENT)
