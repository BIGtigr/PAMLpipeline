#!/bin/bash

################################################################################
##This is a shell script to run PAML in batch mode.
##Prior to running PAML this script checks the header
##in each alignment and corrects the sequence number if it
##is wrong and generats a tree file from a referance tree 
##containing the correct taxa from the alignment. 
##
##To run:
## ./PAMLpipeline.sh /folder/containing/alignment/files Model /path/to/tree/file
##The arguments must be provided in this order
## 1. The path to the folder containing alignment file
## 2. PAML model name (currently only M8 or M8a recognized)
## 3. The file name of the reference tree file
##
## Author: Mariya Shcheglovitova
## Email: m.shcheglovitova@gmail.com
## License: Creative Commons Attribution
#################################################################################

#function to check number of sequences in alignment and fix the alignment header if the sequence number is wrong
FixLineNum(){
#$1 means the first argument recieved by the function
	myfile=$1
	lineNum=`tail -n +2 $myfile | wc -l` #count the number of sequences
	seqLen=`head -n 1 $myfile | awk 'BEGIN {FS=" "};{print $2}'` #extract the number corresponding to sequence length
	replacement=$lineNum" "$seqLen 
	sed -i 1s/.*/"$replacement"/ $myfile #replace the incorrect alignment header  
}

#Store the commandline arguments to this shell script
AlignFolder=$1
Model=$2
TreeFile=$3

#path to Rscript for making trees
RscriptPath="/home/sjosway/Programs/paml/PAMLpipeline/makePAMLtre.R"

#PAML parameters not corresponding to model
CodeMlPar="\nnoisy = 9  *0,1,2,3,9: how much rubbish on the screen\nverbose = 1  *0: concise; 1: detailed, 2: too much\nrunmode = 0  *0: user tree;  1: semi-automatic;  2: automatic\n\t*3: StepwiseAddition; (4,5):PerturbationNNI; -2: pairwise\n\nseqtype = 1  *1:codons; 2:AAs; 3:codons-->AAs\nCodonFreq = 2  *0:1/61 each, 1:F1X4, 2:F3X4, 3:codon table\n\nmodel = 0 *models for codons:\n\t*0:one, 1:b, 2:2 or more dN/dS ratios for branches\n\t*models for AAs or codon-translated AAs:\n\t*0:poisson, 1:proportional, 2:Empirical, 3:Empirical+F\n\t*6:FromCodon, 7:AAClasses, 8:REVaa_0, 9:REVaa(nr=189)\n\nNSsites = 8 *0:one w;1:neutral;2:selection; 3:discrete;4:freqs;\n\t*5:gamma;6:2gamma;7:beta;8:beta&w;9:beta&gamma;\n\t*10:beta&gamma+1; 11:beta&normal>1; 12:0&2normal>1;\n\t*13:3normal>0\n\nfix_kappa = 0  *1: kappa fied, 0: kappa to be estimated\nkappa = 2  *initial or fixed kappa\n"

#PAML parameters for M8a and M8 models
M8aPar="fix_omega = 1  *1: omega or omega_1 fixed, 0: estimate\nomega = 1  *initial or fixed omega, for codons or codon-based AAs"
M8Par="fix_omega = 0  *1: omega or omega_1 fixed, 0: estimate\nomega = 1  *initial or fixed omega, for codons or codon-based AAs"

AlignFileArr=(`ls $AlignFolder`)
echo ${AlignFileArr[@]}

StatFile=$1"/paml-stats.out" #name out file
echo "gene id, model, lnL, kappa" >> $StatFile
 
#Loop through files in the alignment folder
for file in ${AlignFileArr[@]}; 
do 
	myfile=${AlignFolder%%/}/$file # concatonate file name with path
    outfile=$myfile"."$Model".paml.out" #create name for output file: infile.paml.out 
    PAMLfile=$myfile.ctl #create name for PAML .ctl script file: infile.ctl
	FixLineNum $myfile #fix the sequence number in the alignment header
    sed -i 's/\t/  /' $myfile #remove tabs from alignment file 
	Rscript $RscriptPath --infile $myfile --treefile $TreeFile > R.out.tmp #2>&1 #generate the correct tree file for the taxa in the alignment
    #create the PAML .ctl script 
    echo "seqfile = "$myfile > $PAMLfile
    newTree=$myfile".tre"
    echo "treefile = "$newTree >> $PAMLfile
    echo "outfile = "$outfile >> $PAMLfile
    echo -e $CodeMlPar >> $PAMLfile
    if [ "$Model" = "M8a" ] 
    then
        echo -e $M8aPar >> $PAMLfile
    elif [ "$Model" == "M8" ]
    then
        echo -e $M8Par >> $PAMLfile
    fi   
	mygene="${file%%.*}"
	codeml $PAMLfile && mylnL=`grep "lnL(ntime" $outfile | awk '{ print $5}'` && mykappa=`grep "kappa" $outfile | awk '{ print $4}'` && echo $mygene","$Model"," $mylnL","$mykappa >> $StatFile
done
#clean up
#rm R.out.tmp
