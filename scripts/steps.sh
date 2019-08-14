#Copying samples
for i in /dlmp/sandbox/runs/NGS87-MSTR/MSQC_NGS87-MSTR_DNA004242019_NGS87_HKM7TDMXX/MSQC_NGS87-MSTR_DNA004242019_NGS87_HKM7TDMXX_dedup_cat/samples/*; do sam=$(basename $i); mkdir $PWD/$sam; cp $i/*R*_mergedFinalDeduped.fq.gz $PWD/$sam/;done

#BWA Alignment
for i in /dlmp/sandbox/cgslIS/Gopi/Projects/Large_cancer_contamination/run_data/samples/*; do sam=$(basename $i); qsub -V -b y -q sandbox.q -N mgc_bwa_${sam} -l h_vmem=30G -l h_stack=10M -m ea -M sivasankara.gopinath@mayo.edu -e /dlmp/sandbox/cgslIS/Gopi/Projects/Large_cancer_contamination/run_data/logs/ -o /dlmp/sandbox/cgslIS/Gopi/Projects/Large_cancer_contamination/run_data/logs/ /dlmp/sandbox/cgslIS/Gopi/Projects/Large_cancer_contamination/scripts/sentieon_bwa.sh -i $i/*R1*.gz -f $i/*R2*.gz -s $sam -r /dlmp/misc-data/pipelinedata/deployments/mgc/bwa/GRCh37/hs37d5.fa -o $i ; done