#!/bin/bash


############################################################
#
# 
#  This is just a glorified intersect script              
#
#
############################################################

usage ()
{
cat <<EOF
##########################################################################################################
##
## Script Options:
##   Required:
##      -i      full path to bam file
##      -o      output directory
##      -c      config directory
##      -p      panel bed
##      -l      enable logging
####
EOF
exit 1
}

##################################################################################
###
###     Parse Argument variables
###
##################################################################################

while getopts "i:o:c:p:l:" OPTION; do
  case $OPTION in
      i)  INPUT_DIR=$OPTARG ;;
      c)  CONFIG_DIR=$OPTARG ;;
      o)  OUTPUT_DIR=$OPTARG ;;
      p)  PANEL_BED=$OPTARG ;;
      l)  log="TRUE" ;;
      \?) echo "Invalid option: -$OPTARG. See output file for usage." >&2
          usage
          exit ;;
      :)  echo "Option -$OPTARG requires an argument. See output file for usage." >&2
          usage
          exit ;;
  esac
done

if [ "$log" == "TRUE"  ]
then
        set -x
fi

if [ $# -eq 0 ];then
    echo "No arguments supplied"
    usage
    exit 1
fi


if [ -z "${CONFIG_DIR}" ];then
    usage
    exit 1
fi

if [ -z "${INPUT_DIR}" ];then
    usage
    exit 1
fi

if [ -z "${PANEL_BED}" ];then
    usage
    exit 1
fi

source $CONFIG_DIR/verifyBamIdConfig.txt

VERIFYBAMID_OPTIONS="--ignoreRG --verbose --maxDepth 500 --precise --minQ 25"

function create_verify_dir {
    VERIFY_DIR=$OUTPUT_DIR/verifyBamID
    BAM_FILE=$INPUT_DIR
    SAMPLE_NAME=`basename $BAM_FILE | cut -d"." -f1`
    SAMPLE_DIR=$VERIFY_DIR/$SAMPLE_NAME
    if [[ -d $SAMPLE_DIR ]];then
	rm -rf $SAMPLE_DIR
	mkdir -p $SAMPLE_DIR $SAMPLE_DIR/logs
        if [[ -f $BAM_FILE ]];then
	    echo cp $BAM_FILE $SAMPLE_DIR
	    echo cp $BAM_FILE.bai $SAMPLE_DIR
	    pushd $SAMPLE_DIR
	    intersect_1000G $SAMPLE_DIR $SAMPLE_NAME $BAM_FILE
	    popd
        fi
    else
	mkdir -p $SAMPLE_DIR $SAMPLE_DIR/logs
	if [[ -f $BAM_FILE ]];then
	    echo cp $BAM_FILE $SAMPLE_DIR
	    echo cp $BAM_FILE.bai $SAMPLE_DIR
	    pushd $SAMPLE_DIR
	    intersect_1000G $SAMPLE_DIR $SAMPLE_NAME $BAM_FILE
	    popd
	fi	
    fi
}
    

function intersect_1000G {
    SAMPLE_DIR=$1
    SAMPLE_NAME=$2
    BAM=$3
    echo $SNP_1000GENOME_VCF
    echo "$INTERSECTBED -a $SNP_1000GENOME_VCF -b $PANEL_BED -header > $SAMPLE_DIR/1000GENOME_PANEL.vcf"
    $INTERSECTBED -a $SNP_1000GENOME_VCF -b $PANEL_BED -header > $SAMPLE_DIR/1000GENOME_PANEL.vcf
    if [[ -f $SAMPLE_DIR/1000GENOME_PANEL.vcf ]];then
	if [[ $BAM.bai ]];then
	    run_verifybamid $SAMPLE_NAME $SAMPLE_DIR $BAM 
	fi
    fi
}



function run_verifybamid {
    NAME=$1
    SAMPLE_DIR=$2
    BAM=$3
    CMD="$verifyBamID/verifyBamID --vcf $SAMPLE_DIR/1000GENOME_PANEL.vcf --bam $BAM $VERIFYBAMID_OPTIONS --out $NAME.verifybamid --noPhoneHome"
    echo "${CMD}"
    ${CMD}
}

create_verify_dir
#intersect_1000G
