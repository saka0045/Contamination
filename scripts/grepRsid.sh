#!/bin/bash

zgrep -wf /dlmp/sandbox/cgslIS/Yuta/Contamination/files/final_rsid.txt /dlmp/misc-data/reference/bior-catalogues/dbSNP/142_GRCh37.p13/variants_nodups.v1/00-All.vcf.tsv.bgz > /dlmp/sandbox/cgslIS/Yuta/Contamination/files/grepped_final_rsid.txt
