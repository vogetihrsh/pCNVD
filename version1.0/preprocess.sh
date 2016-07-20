#!/bin/bash

#*********************************************************************#
#       AUTHOR: SRIHARSHA VOGETI				      #
#	EMAIL: vogetisri.harsha@research.iiit.ac.in                   #
#   	SOURCE:                                                       #
#   	DESCRIPTION: pCNVD PIPELINE SCRIPT                            #
#   	LAST UPDATED: 18/06/16                                        #
#*********************************************************************#

shopt -s extglob
#set -e 
start_time=`date +%s`


#PARAMETERS WITH DEFAULT VALUES
no_of_procs=32;		# number of processes
input_file="";		# INPUT FILE NAME && MANDATORY PARAMETER
mappability_file=""; 	# MAPPABILITY FILE NAME && MANDATORY PARAMETER
window_file=""; 	# BED FILE CONTAINING WINDOWS && required
output="";      	# OUTPUT PREFIX && MANDATORY PARAMETER

deeptoolFlag=0;		# flag for deepTools (GC-correction)
yoonFlag=0;		# flag for yoon et al method (GC-correction)
gcFlag=0;
SOURCEDIR=$(dirname $(readlink -f $0)); # SOURCE DIRECTORY 

function runYoonGCcorrection() {
	awk '{print $1}' $1 > $1"_GC"
	paste $1"_GC" $2 > $output"_GC"
	Rscript --slave $SOURCEDIR"/gcCorrectionYoon.R" $output"_GC" > $1"_GC";
	awk '{print $2,$3,$4,$5}' $1 | paste $1"_GC" - >$output"_GC"
	mv $output"_GC" $1
	rm $1"_GC";

}
#***************************************#
#	READ OPTIONS FROM CMD 		#
#	AND SET PARAMETERS		#
#***************************************#

SHORTOPTS="ybp:i:o:m:z:"
LONGOPTS="gcfile:"
PROGNAME="preprocess.sh"
ARGS=$(getopt -s bash --options $SHORTOPTS  --longoptions $LONGOPTS --name $PROGNAME -- "$@" ) 

eval set -- "$ARGS"
while true; do
	case "$1" in 
	-p) no_of_procs="$2"; shift 2 ;;
	-i) input_file="$2"; shift 2;;
	-o) output="$2"; shift 2;;
	-m) mappability_file="$2"; shift 2;;
	-z) window_file="$2"; shift 2;;
	-y) yoonFlag=1; shift ;;
	--gcfile) gcFile="$2"; gcFlag=1; shift 2;;
	--) shift; break;;
	*) echo "Error: Something wrong with the parameters"; 
	echo "Requred parameters: -i -o -m -z "; exit 1;;
	esac 
done



# MINIMUM REQUIRED PARAMETERS
if [[ -z "$input_file" || -z "$window_file" || -z "$mappability_file" || -z "$output" ]]; then
	echo "Missing one of the required parameters: window_file (-z) mappability_file (-m) input_file (-i) output (-o) " >&2
	exit 
fi

# FILE DOESNT EXIST ERROR
if [[ ! -f $window_file || ! -f $input_file || ! -f $mappability_file ]]; then 
	echo "One of the input files not found" >&2
	exit 1
fi
if [[ $yoonFlag -eq 1 ]]; then 
	if [[ $gcFlag -eq 1 ]];then
		gcFlag=1;
	else
		echo "ERROR: -y flag requires --gcfile argument" >&2 ;
		exit 1
	fi
fi	

#***********************************************#
#	MAIN FUNCTION STARTS HERE		#
#	PRECPROCESS-SEGMENTATION-POSTPROCESS	#
#***********************************************#

# DATA PREPARATION AND FILTERING 
samtools view -@ 4 -q 1 -bh $input_file > $output"_temp1.bam";
bedtools coverage -abam $output"_temp1.bam" -b $window_file > $output"_temp1.bed";
rm -rf $output"_reads.bed";

sort -n -k2 $output"_temp1.bed" -o $output"_temp1.bed";
paste $output"_temp1.bed" $mappability_file > $output"_temp2";
mv $output"_temp2" $output"_temp1.bed";
awk '{print $4,$5,$8,$2,$3}' $output"_temp1.bed"> $output"_temp1";

# check for gc correction, if yes correct it 
if [[ $yoonFlag -eq 1 ]]; then
	runYoonGCcorrection $output"_temp1" $gcFile;
fi

awk '{if($1!=0&&$2!=0&&$3>=0.5)print $1;}' $output"_temp1" > $output"_pCNVD.input";
awk '{if($1!=0&&$2!=0&&$3>=0.5)print $4,$5;}' $output"_temp1" > $output"_pCNVD.bincor"; 
rm -rf $output"_temp1.bed" $output"_temp1.bam" $output"_temp1";


# check for gc correction flag and run external R script 
##############################################################################################


