#!/usr/bin/env python3

import argparse
from annotateMicrohap import make_microhap_dict
from mismatchSnps import make_vcf_and_bed_files

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-r", "--rsidFile", dest="rsid_file", required=True,
        help="Path to the output microhap site rsid file"
    )
    parser.add_argument(
        "-g", "--greppedRsidFile", dest="grepped_rsid_file", required=True,
        help="Path to the rsid file grepped from dbSNP"
    )
    parser.add_argument(
        "-b", "--bedFile", dest="bed_file", required=True,
        help="Path to the output BED file"
    )
    parser.add_argument(
        "-v", "--vcfFile", dest="vcf_file", required=True,
        help="Path to the output vcf file"
    )

    args = parser.parse_args()

    rsid_file = open(args.rsid_file, "r")
    grepped_rsid_file = open(args.grepped_rsid_file, "r")
    bed_file = open(args.bed_file, "w")
    vcf_file = open(args.vcf_file, "w")

    # Make new BED and VCF file from the new Microhap rsid file filtered for complete microhaps
    microhap_dict = make_microhap_dict(rsid_file)
    grepped_rsid_snps = make_vcf_and_bed_files(bed_file, grepped_rsid_file, microhap_dict, vcf_file)

    print(grepped_rsid_snps)

    rsid_file.close()
    grepped_rsid_file.close()
    bed_file.close()
    vcf_file.close()


if __name__ == "__main__":
    main()
