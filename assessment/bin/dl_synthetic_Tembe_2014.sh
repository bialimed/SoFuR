#!/bin/bash
set -e # exit when any command fails


################################################################################
#
# FUNCTIONS
#
################################################################################
# Download from SRA
download () {
	fastq-dump --split-files --gzip --outdir $2 $1
	if [ $? -ne 0 ]; then
		>&2 echo "Error on $1"
		exit 1
	fi
}

# Rename fastq
rename () {
	mv ${1}_1.fastq.gz ${2}/${1}_R1.fastq.gz && mv ${1}_2.fastq.gz ${2}/${1}_R2.fastq.gz
	if [ $? -ne 0 ]; then
		>&2 echo "Error on $1"
		exit 1
	fi
}


################################################################################
#
# MAIN
#
################################################################################
# Parameters
out_dir="."
if [ $# -eq 1 ]
then
	out_dir=$1
fi

# Download
declare samples=(
	"SRR1544075"
	"SRR1548811"
	"SRR1659951"
	"SRR1659952"
	"SRR1659953"
	"SRR1659954"
	"SRR1659955"
	"SRR1659956"
	"SRR1659957"
	"SRR1659958"
	"SRR1659959"
	"SRR1659960"  # Problem in file: quality always ? in all bases in all reads
	"SRR1659961"
	"SRR1659962"
	"SRR1659963"
	"SRR1659964"
	"SRR1659965"
	"SRR1659966"
	"SRR1659967"
	"SRR1659968"
)


for curr_spl in "${samples[@]}"
do
	echo "Download ${curr_spl} in ${out_dir}"
	download ${curr_spl} ${out_dir} && rename ${curr_spl} ${out_dir}
done

echo "End of job"
