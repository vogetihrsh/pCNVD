SOURCEDIR=$(dirname $(readlink -f $0)); # SOURCE DIRECTORY 
ll=0.55
uu=1.45
bedcnv=".bed"
outputFile=$1
callFile=$2
chrName=$3
output=$4
numWindows=$(wc -l $outputFile| awk '{print $1}')
avg1=$($SOURCEDIR"/calAvg" $numWindows < $outputFile | awk '{print $1}');
lower_cutoff=$(echo $ll $avg1 | awk '{print $1*$2}' )
upper_cutoff=$(echo $uu $avg1 | awk '{print $1*$2}' )
awk -v lc="$lower_cutoff" -v hc="$upper_cutoff" -v outfile="$output$bedcnv" -v avg="$avg1" -v chrName="$chrName" '

# temp function delete after done
function isCopyNumberZero(cAvg,cCount)
{
	average = cAvg/cCount;
	average = (average*2)/avg;
	return int(average + 0.5);
}

#CONDITION IF TWO EVENTS SHOULD BE MERGED OR NOT 
function shouldMerge(prevStart, prevEnd, curStart, curEnd)
{
	Ratio=(curStart-prevEnd-1)/(curEnd-prevStart+1);
	if(Ratio<0.2)
		return 1;
	else 
		return 0;
}

function absolute(n){
	if(n<0)
		return -n;
	else
		return n;
}

function checkzero(w1,w2,c1,c2){
	if(c1<0.55 && c2<0.55 && (w2-w1)<10000)
		return 1;
	else
		return 0;
}

BEGIN {
	entryPointer=-1;
	
	prev=-1;
	cnvType=-1;
	curAvg=0;
	count=0;
	
	prevRD=-1;
	prevEndPoint=-1;
	prevStart=-1;
	
	PTR=0;
	diff=0;
}

{
	diff=absolute(prevRD-$3);
	if(entryPointer==1&&($3<=lc||$3>=hc)&&(diff<avg/2)&&prevEndPoint==$1)
	{
		curAvg=curAvg+$3;
		count=count+1;
	}

	else if(entryPointer==1)
	{
		entryPointer=-1;
		epoint=prevEndPoint;
		curAvg=curAvg/count;

		cn=(curAvg*2)/avg;
		if(count>1){
			PTR=PTR+1;
			CNVARR[PTR,1]=spoint;CNVARR[PTR,2]=epoint;CNVARR[PTR,3]=cnvType;CNVARR[PTR,4]=cn;
		}
		cnvType=-1;
		curAvg=0;
		count=0;
	}

	if(entryPointer==-1 && ($3<=lc || $3>=hc) )
	{
		entryPointer=1;
		spoint=$1;

		if($3<=lc)
			cnvType=0;
		else
			cnvType=1;
		count = count +1;
		curAvg = curAvg + $3;
	}
	prevEndPoint = $2;
	prevStart=$1;
	prevRD=$3;
}

END{
	FLAG=0;
	CSTART=-1;CSTOP=-1;CEVENT=-1;CCPOY=0;	#CURRENT START, STOP, TYPE OF EVENT AND COPY NUMBER 
	MAX_WIN=0;	#MAX WINDOW length IN THE CNVS PREDICTED
	i=1;
	
	#WHILE LOOP FOR MERGING CNVS AND WRITTING THE RESULTS TO OUTPUT FILE 
	while(i<=PTR){
		if(FLAG==0)
		{
			CSTART=CNVARR[i,1];
			CSTOP=CNVARR[i,2];
			CEVENT=CNVARR[i,3];
			CCOPY=CNVARR[i,4];
			FLAG=1;
			i++;
		}
		else if(CEVENT==CNVARR[i,3]&& absolute(CCOPY-CNVARR[i,4])<0.5&& (shouldMerge(CSTART,CSTOP,CNVARR[i,1],CNVARR[i,2])==1||checkzero(CSTOP,CNVARR[i,1],CCOPY,CNVARR[i,4])==1)){
			t1=(CSTOP-CSTART);
			t2=CNVARR[i,2]-CNVARR[i,1];
			CCOPY=(t1*CCOPY+t2*CNVARR[i,4])/(t1+t2);
			CSTOP=CNVARR[i,2];
			i++;
		}
		else{
			printf ("%s\t%d\t%d\t%d\t%.2f\n",chrName,CSTART,CSTOP,CEVENT,CCOPY) >> outfile;
			FLAG=0;
			
			# CALCULATE MAXIMUM WINDOW LENGTH
			temp=CSTOP-CSTART;
			if(MAX_WIN<temp)
				MAX_WIN=temp;
		}
	}

	#PRINT THE LEFTOVER CNV, IF ANY
	if(FLAG){
			printf ("%s\t%d\t%d\t%d\t%.2f\n",chrName,CSTART,CSTOP,CEVENT,CCOPY) >> outfile;
			
			# CALCULATE MAXIMUM WINDOW LENGTH
			temp=CSTOP-CSTART;
			if(MAX_WIN<temp)
				MAX_WIN=temp;
		#	printf("%d",MAX_WIN);	
	}
}
'   $callFile
rm -rf $callFile
