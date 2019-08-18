#!/bin/bash

usage() {
cat <<EOF
  
 Process given fastq files(paired/single) using Sentieon's BWA aligner and somatic variant caller

  OPTIONS:
	-i path to pair of samples with fastq files under each sample folder (required)
	-p list of percentage separated by comma (required)
	-r reference (required)
	-o output path (required)
	
EOF
}

while getopts "hi:o:r:p:" OPTION
do
	case $OPTION in
		h) usage ; exit 1 ;;
		i) data_path="$OPTARG" ;;
		o) out_path="$OPTARG" ;;
		r) reference="$OPTARG" ;;
		p) percent_list="$OPTARG" ;;
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

IFS=, read -ra percent_values <<< "$percent_list"
source /dlmp/sandbox/cgslIS/DLMP_CGSL_OS/python3_env/bin/activate
contaminator_script="/dlmp/sandbox/cgslIS/Gopi/Projects/LargeCancer_contamination/scripts/contaminate_samples.py"

for pair in ${data_path}/pair*; do 
	echo $pair
	pair_name=$(basename $pair)
	sample1="${pair}/*1"
	samples="${pair}/*2"
	output=${out_path}/${pair_name}
	logs=${output}/logs

	echo -e "\n\n" $pair_name "" 
	mkdir -p  $output
	mkdir -p $logs

	for percent in "${percent_values[@]}"; do
		echo -e "python /dlmp/sandbox/cgslIS/Gopi/Projects/Large_cancer_contamination/scripts/contaminate_samples.py -a $sample1 -b $samples -p $percent -o $output"
		qsub -V -b y -q sandbox.q -N contaminator-${percent}percent -l h_vmem=80G -l h_stack=15M -m ea -M sivasankaran.gopinath@mayo.edu -e $logs -o $logs python $contaminator_script -a $sample1 -b $samples -p $percent -r $reference -o $output 
	done 

done