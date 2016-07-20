#!/bin/bash

#*********************************************************************#
#       AUTHOR: SRIHARSHA VOGETI				      #
#	EMAIL: vogetisri.harsha@research.iiit.ac.in                   #
#   	SOURCE:                                                       #
#   	DESCRIPTION: segmentation script in pCNVD pipeline            #
#   	LAST UPDATED: 13/07/16                                        #
#*********************************************************************#

shopt -s extglob
#set -e 
start_time=`date +%s`


#PARAMETERS WITH DEFAULT VALUES
function printStderr {
	echo "$@" >&2;
}

# GET CHROMOSOME FUNCTION 
function retChrom {
	windowFile=$1
	cName=$(head -1 $windowFile | awk '{print $1}')
	echo $cName
}

#***********************************#
#	CODE FOR DNA COPY	    #
#***********************************#
function runDNACopy {
	# Run R script and generate segments 
	Rscript $SOURCEDIR/RunDNACopy.R $output"_pCNVD.input" $numWindows $noOfProcesses > $output".Dtemp"
	rm -rf $output"_dnacopy_pCNVD.output"
	# convert output into .input value
	awk -v outputFile=$output"_dnacopy_pCNVD.output" ' NR>5 {
		for(i=1; i<=$6; ++i){
			   print $7 >> outputFile
			}
		}' $output".Dtemp"
	rm -rf $output".Dtemp"
}


#*********************************#
# CODE FOR RUNNING TV ALGORITHM   #
# DIVIDE INPUT FILE INTO CHUNKS   #
# RUN SEGMENTATION FOR EACH CHUNK #
# MERGE BACK CHUNKS 		  # 
#*********************************#
function runTVAlgorithm {
	
	# calculate number of entries in each chunk 
	rm -rf $output"_inp"*
	y=$(wc -l $output"_pCNVD.input" | awk '{print $1}')
	N=$y
	y=`expr $y / $noOfProcesses`;
	split -l $y $output"_pCNVD.input" $output"_inp";
	p=`expr $noOfProcesses - 1`
	q=`expr $p + 1`
	k=0
	FILE=$output"_inp"$q;
		
	# change splits name
	for i in $( ls $output"_inp"* )
	do
	mv -f $i $output"_inp"$k
	((k++))
	done
	
	# check for the last remaining input values
	if [ -f $FILE ];
	then
		cat $FILE >> $output"_inp"$p
		rm $output"_inp"$q
	fi
	

	# comes into play when creating overlapping input files, otherwise has no affect. But needded
#	stop1=`expr $noOfProcesses - 1`
#	for((i=0; i<stop1; i++ )); do
#		j=`expr $i + 1`
		#tail -20 $output"_inp"$i > $output$tempString
#		cat $output"_inp"$j > $output$tempString
#		mv $output$tempString $output"_inp"$j
#	done

	# run segmentation algorith using segment 
	mpirun -np $noOfProcesses $SOURCEDIR/segment $output;
	rm -rf $output"_inp"*;
	rm -rf $output"_tvm_pCNVD.output"
			
	# merge segmented chunk files 
	for ((n=0;n<$noOfProcesses;n++))
	do
		cat $output"_out"$n >> $output"_tvm_pCNVD.output"
		rm -rf $output"_out"$n
	done

}



#***********************************************#
#	MAIN FUNCTION STARTS HERE		#
#	PRECPROCESS-SEGMENTATION-POSTPROCESS	#
#***********************************************#


##############################################################################################
# varaible declarations
outputPrefix="";
noOfProcesses=32;
tvmFlag=0;
dnaCopyFlag=0;
SOURCEDIR=$(dirname $(readlink -f $0));

while getopts 'p:o:td' flag; do
        case "${flag}" in                    
          o) outputPrefix="${OPTARG}"  ;;
          p) noOfProcesses="${OPTARG}" ;;  
          t) tvmFlag=1;;
	  d) dnaCopyFlag=1 ;;
	  \?) echo "Invalid option: -$OPTARG" >& 2 exit ;;
	  esac
done

output=$outputPrefix
inputFile=$output"_pCNVD.input"

if [[ ! -f "$inputFile" ]]; then
         echo "ERROR: input file" $inputFile "not found. Check if such a file exists and correct prefix is passed to -o" >&2
	exit
fi	
if [[ tvmFlag -eq 0 && dnaCopyFlag -eq 0 ]]; then
	echo "Requires flag anyone of the flags -t and -d"
	exit
fi	

numWindows=$(wc -l $output"_pCNVD.input" | awk '{print $1}')

### CALL SEGMENTATION ALGORITHMS #######
if [[ tvmFlag -eq 1 ]]; then 
	runTVAlgorithm ;
fi	

if [[ dnaCopyFlag -eq 1 ]]; then 
	runDNACopy ;
fi	

#################################################################################################
