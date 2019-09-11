#!/usr/bin/env python3

import json
import argparse
from annotateMicrohap import make_microhap_dict

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-r", "--rsidFile", dest="rsid_file", required=True,
        help="Path to rsid file"
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
    parser.add_argument(
        "-m", "--microhapFile", dest="microhap_file", required=True,
        help="Path to the microhap tsv file"
    )

    args = parser.parse_args()

    final_rsid_file = open(args.rsid_file, "r")
    grepped_rsid_file = open(args.grepped_rsid_file, "r")
    bed_file = open(args.bed_file, "w")
    vcf_file = open(args.vcf_file, "w")
    microhap_file_path = args.microhap_file

    final_rsid_snps = make_rsid_list(final_rsid_file)

    microhap_dict = make_microhap_dict(microhap_file_path)

    grepped_rsid_snps = make_vcf_and_bed_files(bed_file, grepped_rsid_file, microhap_dict, vcf_file)

    # print(grepped_rsid_snps)
    print(len(grepped_rsid_snps))

    for snp in final_rsid_snps:
        if snp not in grepped_rsid_snps:
            print(snp + " not found")

    final_rsid_file.close()
    grepped_rsid_file.close()
    bed_file.close()
    vcf_file.close()


def make_vcf_and_bed_files(bed_file, grepped_rsid_file, microhap_dict, vcf_file):
    """
    Makes the VCF and BED files for the given microhaplo sites. Requires the microhap dictionary, which can be
    made using make_microhap_dict()
    :param bed_file:
    :param grepped_rsid_file:
    :param microhap_dict:
    :param vcf_file:
    :return: VCF and BED files
    """
    # Make vcf file header
    vcf_file.write("##fileformat=VCFv4.1\n")
    vcf_file.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\n")
    grepped_rsid_snps = []
    for line in grepped_rsid_file:
        line = line.rstrip()
        line_item = line.split("\t")
        snp_info = line_item[3]
        # convert the snp info string into dictionary
        snp_info_dict = json.loads(snp_info)
        grepped_snp_id = snp_info_dict["ID"]
        chrom_number = str(line_item[0])
        chrom = "chr" + chrom_number
        pos = snp_info_dict["POS"]
        ref = snp_info_dict["REF"]
        alt = snp_info_dict["ALT"]
        qual = snp_info_dict["QUAL"]
        filter_text = snp_info_dict["FILTER"]
        info = "."
        format = "."
        start_pos = int(pos) - 1
        stop_pos = int(pos)
        # make vcf file
        vcf_file.write(chrom + "\t" + pos + "\t" + grepped_snp_id + "\t" + ref + "\t" + alt + "\t" + qual + "\t" +
                       filter_text + "\t" + info + "\t" + format + "\n")
        # for bed file, don't repeat regions
        if grepped_snp_id not in grepped_rsid_snps:
            grepped_rsid_snps.append(grepped_snp_id)
            if start_pos + 1 != stop_pos:
                print(grepped_snp_id + " is not a snp")
            # Annotate the BED file with {MicroHapSnpID}:{NumberOfSnps}
            microhap_site_list = []
            for key in microhap_dict.keys():
                if grepped_snp_id in microhap_dict[key]:
                    microhap_site_list.append(key)
                    continue  # Account for SNPs that are in multiple Microhap sites
            if microhap_site_list == []:
                microhap_site_list = ["na"]
            else:
                for index in range(len(microhap_site_list)):
                    microhap_site_list[index] = microhap_site_list[index] + ":" + \
                                                str(len(microhap_dict[microhap_site_list[index]]))
            bed_file.write(chrom + "\t" + str(start_pos) + "\t" + str(stop_pos) + "\t" + grepped_snp_id +
                           "\t" + ",".join(microhap_site_list) + "\n")
        else:
            print(grepped_snp_id + " is repeated in dbSNP")
    return grepped_rsid_snps


def make_rsid_list(final_rsid_file):
    """
    Makes a list of SNP RSID from the RSID file, removing any duplicate RSIDs
    :param final_rsid_file:
    :return: List of unique SNP RSIDs
    """
    final_rsid_snps = []
    for line in final_rsid_file:
        line = line.rstrip()
        if line not in final_rsid_snps:
            final_rsid_snps.append(line)
        else:
            print(line + " is a duplicate entry")
    return final_rsid_snps


if __name__ == "__main__":
    main()
