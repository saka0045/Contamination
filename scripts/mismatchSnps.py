#!/usr/bin/env python3

import json
from annotateMicrohap import make_microhap_dict

final_rsid_file = open("/Users/m006703/Contamination/files/final_rsid.txt", "r")
grepped_rsid_file = open("/Users/m006703/Contamination/files/grepped_final_rsid.txt", "r")
bed_file = open("/Users/m006703/Contamination/files/contamination_target.bed", "w")
vcf_file = open("/Users/m006703/Contamination/files/contamination.vcf", "w")
microhap_file_path = "/Users/m006703/Contamination/files/microhaps_rsid.tsv"

final_rsid_snps = []
for line in final_rsid_file:
    line = line.rstrip()
    if line not in final_rsid_snps:
        final_rsid_snps.append(line)
    else:
        print(line + " is a duplicate entry")

# print(final_rsid_snps)
# print(len(final_rsid_snps))

# Make vcf file header
vcf_file.write("##fileformat=VCFv4.1\n")
vcf_file.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\n")

microhap_dict = make_microhap_dict(microhap_file_path)

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
        microhap_site_list = []
        for key in microhap_dict.keys():
            if grepped_snp_id in microhap_dict[key]:
                microhap_site_list.append(key)
                continue
        if microhap_site_list == []:
            microhap_site_list = ["na"]
        else:
            for index in range(len(microhap_site_list)):
                microhap_site_list[index] = microhap_site_list[index] + "[" + \
                                            str(len(microhap_dict[microhap_site_list[index]])) + "]"
        bed_file.write(chrom + "\t" + str(start_pos) + "\t" + str(stop_pos) + "\t" + grepped_snp_id +
                       "\t" + ",".join(microhap_site_list) + "\n")
    else:
        print(grepped_snp_id + " is repeated in dbSNP")

# print(grepped_rsid_snps)
print(len(grepped_rsid_snps))

for snp in final_rsid_snps:
    if snp not in grepped_rsid_snps:
        print(snp + " not found")

final_rsid_file.close()
grepped_rsid_file.close()
bed_file.close()
vcf_file.close()
