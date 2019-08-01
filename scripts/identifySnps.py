#!/usr/bin/env python3
"""
Takes the snp covered in the respective assay and filters out for complete microhap sites and creates
a new microhap rsid file
"""

import argparse


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-s", "--snpFile", dest="snp_file", required=True,
        help="Path to the BED file that contains the list of SNPs in the microhap sites that are covered by the panel"
    )
    parser.add_argument(
        "-r", "--rsidFile", dest="rsid_file", required=True,
        help="Path to the output microhap site rsid file"
    )

    args = parser.parse_args()

    snp_file = open(args.snp_file, "r")
    rsid_file = open(args.rsid_file, "w")

    # Gather information from the grepped BED file
    bed_file_info = gather_bed_file_info(snp_file)

    print(bed_file_info)

    # Make Microhap rsid tsv file filtered for complete Microhap sites
    for microhap in bed_file_info.keys():
        if microhap == "na":
            rsid_file.write("na")
            for snp in bed_file_info[microhap]:
                rsid = snp["rsid"]
                rsid_file.write("\t" + rsid)
            rsid_file.write("\n")
        else:
            microhap_site = microhap.split(":")[0]
            number_of_snps = int(microhap.split(":")[1])
            number_of_covered_snps = len(bed_file_info[microhap])
            # Making sure the microhap is completely covered
            if number_of_snps == number_of_covered_snps:
                rsid_file.write(microhap_site)
                for snp in bed_file_info[microhap]:
                    rsid = snp["rsid"]
                    rsid_file.write("\t" + rsid)
                rsid_file.write("\n")

    snp_file.close()
    rsid_file.close()


def gather_bed_file_info(snp_file):
    bed_file_info = {}
    for line in snp_file:
        line = line.rstrip()
        line_item = line.split("\t")
        chrom = line_item[0]
        start_pos = line_item[1]
        stop_pos = line_item[2]
        rsid = line_item[3]
        snp_info = {}
        snp_info["rsid"] = rsid
        snp_info["chrom"] = chrom
        snp_info["start"] = start_pos
        snp_info["stop"] = stop_pos
        microhap_sites = line_item[4].split(",")
        for microhap in microhap_sites:
            if microhap not in bed_file_info.keys():
                bed_file_info[microhap] = [snp_info]
            else:
                bed_file_info[microhap].append(snp_info)
    return bed_file_info


if __name__ == "__main__":
    main()
