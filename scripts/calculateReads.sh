#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

OUTDIR=""
SAMPLE1_NAME=""
SAMPLE2_NAME=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
concatenates fastq files from all lanes, but separate out by
different reads

OPTIONS:
    -h  [optional] help, show this message
    -i  [required] output directory where {Sample}.results.txt is from countFastqFile.sh
    -a  [required] sample 1 name
    -b  [required]  sample 2 name

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "ho:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		o) OUTDIR=${OPTARG} ;;
    esac
done