#!/bin/bash

qsub -V -b y -m abe -M sakai.yuta@mayo.edu -q sandbox.q -N mixFastqs -wd /dlmp/sandbox/cgslIS/Yuta /dlmp/sandbox/cgslIS/Yuta/Contamination/scripts/contaminate_samples.py -a /dlmp/sandbox/runs/NGS87-MSTR/NGS87-MSTR_DNA05132019_NGS87_HKLCLDMXX/samples/006-D01S -b /dlmp/sandbox/runs/NGS87-MSTR/NGS87-MSTR_DNA05132019_NGS87_HKLCLDMXX/samples/009-D01S -p 10 -o /dlmp/sandbox/cgslIS/Yuta/Contamination/Large_Cancer/fastqs/
