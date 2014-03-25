#!/bin/bash

FixLineNum(){
#$1 means the first argument recieved fy function
	myfile=$1
	lineNum=`tail -n +2 $myfile | wc -l`
	seqLen=`head -n 1 $myfile | awk 'BEGIN {FS=" "};{print $2}'`
	replacement=$lineNum" "$seqLen
	sed -i 1s/.*/"$replacement"/ $myfile  
}


AlignFolder=$1
Model=$2
##PATH TO TREE FILE

for file in `ls $AlignFolder`; 
do 
	myfile=$AlignFolder"/"$file
	FixLineNum $myfile
    Rscript makePAMLtre.R --infile $myfile > R.out.tmp 2>&1
done
