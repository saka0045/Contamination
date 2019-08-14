#!/dlmp/sandbox/cgslIS/DLMP_CGSL_OS/python3_env/bin/python

import os
import argparse
import subprocess
from pathlib import Path
from multiprocessing import Pool

#######################################################################
'''This program Randomly Subsamples reads from 2 samples and makes a sample

Usage: python MixSamples.py -a <Test1_path> -b <Test2_path> -o <OutPutPath>

Author: Gopinath Sivasankaran
Contact: Sivasankaran.Gopinath@mayo.edu

NOTE: seqtk path hardcoded
'''
#######################################################################


def main():

    sample1, sample2, out_path, reference, percent = get_args()
    io_obj = PrepareInputOutput(sample1, sample2, percent, out_path)
    out_path = io_obj.prep_output_folders()
    fastq_pair_dict = io_obj.mix_content_dict

    print(f"\n-----------Percent: {percent}------------")
    mix_obj = MixSample(fastq_pair_dict, int(percent), reference, out_path)
    mix_obj.mix_samples()


def get_args():
    Usage = '''\n\npython MixSamples.py -a <Test1_path> -b <Test2_path> -o <OutPutPath>\n
    ****** Please use qsub to run this script as it requires more memory depending on input data size ****'''
    parser = argparse.ArgumentParser(usage=Usage)
    parser.add_argument('-a', '--sample1', dest="s1", help="path to sample1 R1 file.", required=True)
    parser.add_argument('-b', '--sample2', dest="s2", help="path to sample2 R1 file.", required=True)
    parser.add_argument('-r', '--ref', dest="ref", help="path to reference file ", required=True)
    parser.add_argument("-p", '--percentages', dest="percentages", help="contamination percent seperated by comma", required=True)
    parser.add_argument("-o", '--outpath', dest="out", help="path to output", required=True)
    options = parser.parse_args()

    return os.path.abspath(options.s1), os.path.abspath(options.s2), os.path.abspath(options.out), os.path.abspath(options.ref), options.percentages


class PrepareInputOutput():

    def __init__(self, sample1, sample2, percent, out_path):
        self.out_path = out_path
        self.percent = percent
        self.mix_content_dict = {}
        self.s1_fastqs = self.get_fastqs(sample1)
        self.s2_fastqs = self.get_fastqs(sample2)
        self.get_mix_dict()

    @staticmethod
    def get_fastqs(sample_path):
        fastq_files = []
        for file in sorted(os.listdir(sample_path)):
            if "_R" in file and file.endswith('fq.gz') or file.endswith('fastq.gz'):
                fastq_files.append(os.path.join(sample_path, file))
        if not fastq_files:
            sys.exit(f"\nERROR: Fastq file with 'R1' or 'R2' not present in {sample_path}")

        return fastq_files

    def get_mix_dict(self):
        if not len(self.s1_fastqs) and len(self.s2_fastqs):
            raise FileNotFoundError('Number of fastq files in both samples are not same')
        else:
            self.mix_content_dict = dict(zip(self.s1_fastqs, self.s2_fastqs))

    def prep_output_folders(self):
        
        folder_name =  'sample1_' + str(100 - int(self.percent)) + '_sample2_' + self.percent
        percent_out_path = self.out_path + '/' + folder_name
        if not os.path.exists(percent_out_path):
            os.makedirs(percent_out_path)
            
        return percent_out_path


class MixSample():

    def __init__(self, sample_pair_dict, percent, ref, out_path):
        self.reference = ref
        self.percent = percent
        self.out_path = out_path
        self.sample_pair_dict = sample_pair_dict
        self.seqtk = "/usr/local/biotools/seqtk/1.3-r106/seqtk"
        self.sentieon_script = os.path.dirname(os.path.abspath(__file__)) + "/run_sentieon.sh"

    def mix_samples(self):

        seed = 100
        self.job_ids = []
        self.paired_end = False
        self.logs = self.out_path + '/logs'
        if not os.path.exists(self.logs): os.mkdir(self.logs)

        for sample1 in self.sample_pair_dict:
            sample2 = self.sample_pair_dict[sample1]

            if 'R2' in sample1 or 'R2' in sample1:
                self.paired_end = True

            p = Pool(2)
            sample1_readcount, sample2_readcount = p.map(self.get_read_count, [sample1, sample2])

            print("\nInput fastq:\n")
            out_fastq, sample_name = self.get_out_fastq_name(Path(sample1).stem.split('_', 2)[2])
            s1_required_reads = int(sample1_readcount * (100 - self.percent) / 100)
            s2_required_reads = int(sample2_readcount * self.percent / 100)
            print(f'{sample1}\n Total: {sample1_readcount} reads\trequired: {100 - self.percent}%, {s1_required_reads} reads')
            print(f'{sample2}\n Total: {sample2_readcount} reads\trequired: {self.percent}%, {s2_required_reads} reads')

            if self.percent != 0:
                s1_cmd = f'{self.seqtk} sample -s {str(seed)} {sample1} {str(s1_required_reads)}'
                s1_qsub = f'qsub -V -b y -q sandbox.q -N py-seqtk-{self.percent}-f1 -l h_vmem=150G -l h_stack=15M -m ea -e {self.logs} -o {out_fastq}.tmp.fq1 "{s1_cmd}"'
                out1, err1 = self.subprocess_cmd(s1_qsub)
                self.job_ids.append(out1.split(' ')[2].strip())
            if self.percent != 100:
                s2_cmd = f'{self.seqtk} sample -s {str(seed)} {sample2} {str(s2_required_reads)}'
                s2_qsub = f'qsub -V -b y -q sandbox.q -N py-seqtk-{self.percent}-f2 -l h_vmem=150G -l h_stack=15M -m ea -e {self.logs} -o {out_fastq}.tmp.fq2 "{s2_cmd}"'
                out2, err2 = self.subprocess_cmd(s2_qsub)
                self.job_ids.append(out2.split(' ')[2].strip())
            print(f'\ns1_qsub:\n {s1_qsub}\n out1-{out1}, error- {err1} \n\n s2_qsub:\n{s2_qsub}\n out2-{out2}, error {err2}')
        
        self.process_fastq()

    def process_fastq(self):

        r1_fastq, sample_name = self.get_out_fastq_name('R1.fq')
        r2_fastq, sample_name = self.get_out_fastq_name('R2.fq')

        if self.paired_end:
            s3_cmd = f'cat {self.out_path}/*R1*f*q* > {r1_fastq} ; cat {self.out_path}/*R2*f*q* > {r2_fastq}; gzip {r1_fastq} {r2_fastq}; rm {self.out_path}/*tmp.fq*'
            sentieon_cmd = f'{self.sentieon_script} -a {r1_fastq}.gz -b {r2_fastq}.gz -s {sample_name} -r {self.reference} -o {self.out_path}'
        else:
            s3_cmd = f'cat {self.out_path}/*R1*q* > {r1_fastq} ; gzip {r1_fastq} ; rm {self.out_path}/*fastq*'
            sentieon_cmd = f'{self.sentieon_script} -a {r1_fastq}.gz -s {sample_name} -r {self.reference} -o {self.out_path}'

        job_ids = ','.join(self.job_ids)
        s3_qsub = f'qsub -V -b y -q sandbox.q -N cleanup-{self.percent} -hold_jid {job_ids} -l h_vmem=120G -l h_stack=15M -m ea -e {self.logs} -o {self.logs} "{s3_cmd}"'
        out3, err3 = self.subprocess_cmd(s3_qsub)
        print(f'\n\nCleanup_cmd:\n {s3_qsub}, out-{out3}, err-{err3}')

        fq_job_id = out3.split(' ')[2].strip()
        sentieon_qsub =  f'qsub -V -b y -v SENTIEON_LICENSE=dlmpcim03.mayo.edu:8990 -q sandbox.q -N mgc_sentieon-{self.percent} -hold_jid {fq_job_id} -l h_vmem=150G -l h_stack=15M -m ea -e {self.logs} -o {self.logs} {sentieon_cmd}'
        out4, err4 = self.subprocess_cmd(sentieon_qsub)
        print(f'\nsentieon_cmd:\n {sentieon_qsub}, out-{out4}, err-{err4}')
        sentieon_job_id = out4.split(' ')[2].strip()

    def get_read_count(self, sample_fq):
        cmd = "zcat " + sample_fq + " | wc -l"
        lines_in_fq, error = self.subprocess_cmd(cmd)
        return int(float(str(lines_in_fq).split()[0])/float(4))  # 4lines in fq is one read

    def get_out_fastq_name(self, name):
        out_fastq_name = self.out_path.split('/')[-1]
        return os.path.join(self.out_path, out_fastq_name + '_' + name), out_fastq_name

    @staticmethod
    def subprocess_cmd(cmd):
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        return out.decode("utf-8"), err.decode("utf-8")


if __name__ == '__main__':
    main()
