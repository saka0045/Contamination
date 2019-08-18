#!/bin/bash

usage() {
cat <<EOF
  
 Process given fastq files(paired/single) using Sentieon's BWA aligner and somatic variant caller

  OPTIONS:
	-a is R1 file (required)
	-b is R2 file (optional)
	-r is reference (required)
	-s samplename (required)
	-o output path (required)
	
EOF
}

while getopts "ha:b:r:s:o:" OPTION
do
	case $OPTION in
		h) usage ; exit 1 ;;
		a) declare -r r1_fq="$OPTARG" ;;
		b) declare -r r2_fq="$OPTARG" ;;
		r) declare -r reference="$OPTARG" ;;
		o) declare -r out_path="$OPTARG" ;;
		s) declare -r sample_name="$OPTARG" ;;
		?) usage ; exit ;;
	esac
done

if [ $# -eq 0 ];then
	echo -e "No arguments supplied"
	usage
	exit 1
elif [[ $# -lt 8 ]];then
	echo -e "\nERROR: required arguments not provided\n"
	usage
	exit 1
fi

#-------------Tools-----------
BWA=/biotools/biotools/sentieon/201808.03/bin/bwa
SAMTOOLS=/usr/local/biotools/samtools/1.3/samtools
SENTIEON=/biotools/biotools/sentieon/201808.03/bin/sentieon

#-----------Functions---------

function check_file_existence() {
	if [ ! -f "${1}" ]; then
		echo -e "\n\nERROR: ${1} does not exist!\n"
		#log "DEBUG" $__base "ERROR: ${1} does not exist!"
		exit 1
	fi
}

function check_folder_existence() {
	if [[ ! -d "${1}" ]]; then
		echo -e "\n\nERROR: required dir ${1} does not exist!\n"
		exit 1
	fi
}


#------Checking inputs and neccessary files-----

check_file_existence $r1_fq
check_file_existence $reference
check_folder_existence $out_path
if [ "$r2_fq" ] ; then paired_end=true; check_file_existence $r2_fq; fi

# checking required sentieon bwa reference files
declare -a required_ref_files
required_ref_files=(".fa" ".fai" ".sa" ".pac" ".ann" ".bwt" ".amb" ".dict")
for ext in "${required_ref_files[@]}"; do
	ref_name=$(basename $reference)
	ref_path=$(dirname $reference)
	file_to_check=${ref_path}/${ref_name%.fa}*${ext}
	check_file_existence ${file_to_check}
done

bam_file=${out_path}/${sample_name}.bam
unsorted_bam=${out_path}/${sample_name}_unsorted.bam
output_vcf=${out_path}/${sample_name}.vcf


#----------Alignment-------

if [ "$paired_end" = true ]; then
	echo -e "\n\nRunning BWA alignment on paired end data...\n"
	$BWA mem -R "@RG\tID:${sample_name}\tPU:ILLUMINA\tSM:${sample_name}\tPL:ILLUMINA\tLB:LIB\tCN:CGSL" -K 10000000 -t 32 ${reference} ${r1_fq} ${r2_fq} | $SAMTOOLS view -bS > ${unsorted_bam}
else
	echo -e "\n\nRunning BWA alignment on single end data...\n"
	$BWA mem -R "@RG\tID:${sample_name}\tPU:ILLUMINA\tSM:${sample_name}\tPL:ILLUMINA\tLB:LIB\tCN:CGSL" -K 10000000 -t 32 ${reference} ${r1_fq} | $SAMTOOLS view -bS > ${unsorted_bam} 	
fi

echo -e "\n\nSorting bam file...\n"
$SAMTOOLS sort -o ${bam_file} ${unsorted_bam}
$SAMTOOLS index ${bam_file}
rm ${unsorted_bam}


#---------Variant calling--------

#echo -e "\n\nperforming variant calling..."
#$SENTIEON driver -i ${bam_file} -r ${reference} --algo TNhaplotyper2 ${output_vcf} --tumor_sample ${sample_name}

