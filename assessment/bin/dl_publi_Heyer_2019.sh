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
	mv $2/$1_1.fastq.gz $2/$1_R1.fastq.gz && \
	mv $2/$1_2.fastq.gz $2/$1_R2.fastq.gz
	if [ $? -ne 0 ]; then
		>&2 echo "Error on $1"
		exit 1
	fi
}

# Clean constant sequence starting reads
cutseq () {
	mv $2/$1_R1.fastq.gz $2/$1_R1_tmp.fastq.gz && \
	cutadapt -u 12 -o $2/$1_R1.fastq.gz $2/$1_R1_tmp.fastq.gz && \
	rm $2/$1_R1_tmp.fastq.gz && \
	mv $2/$1_R2.fastq.gz $2/$1_R2_tmp.fastq.gz && \
	cutadapt -u 12 -o $2/$1_R2.fastq.gz $2/$1_R2_tmp.fastq.gz && \
	rm $2/$1_R2_tmp.fastq.gz
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
declare -a samples=(
	"SRR7646882"
	"SRR7646883"
	# "SRR7646885"  # Fusion not verified by other method
	"SRR7646890"
	"SRR7646896"
	"SRR7646898"
	# "SRR7646901"  # Mate partner unknown 
	"SRR7646902"
	"SRR7646906"
	"SRR7646907"
	"SRR7646914"
	"SRR7646915"
	"SRR7646917"
	"SRR7646919"
	"SRR7646924"
	"SRR7646926"
	"SRR7646927"
	"SRR7646928"
	"SRR7646929"
	"SRR7646930"
	"SRR7646931"
	"SRR7646932"
	"SRR7646933"
	"SRR7646934"
	"SRR7646935"
	"SRR7646936"
	# "SRR7646937"  # Problem in file: Reads are improperly paired
	"SRR7646942"
	"SRR7646948"
	"SRR7646951"
	"SRR7646952"
	"SRR7646955"
	"SRR7646961"
	"SRR7646962"
	"SRR7646963"
	"SRR7646965"
	"SRR7646966"
	"SRR7646967"
	"SRR7646879"
	"SRR7646895"
	"SRR7646899"
	"SRR7646904"
	"SRR7646964"
)

declare -a samples_to_clean=(
	"SRR7646890"
	"SRR7646895"
	"SRR7646896"
	"SRR7646898"
	"SRR7646902"
	"SRR7646904"
	"SRR7646906"
	"SRR7646907"
	"SRR7646915"
	"SRR7646917"
	"SRR7646919"
	"SRR7646926"
	"SRR7646927"
	"SRR7646928"
	"SRR7646929"
	"SRR7646930"
	"SRR7646931"
	"SRR7646932"
	"SRR7646933"
	"SRR7646934"
	"SRR7646935"
	"SRR7646936"
	# "SRR7646937"
	"SRR7646961"
	"SRR7646966"
	"SRR7646967"
)


for curr_spl in "${samples[@]}"
do
	echo "Download ${curr_spl} in ${out_dir}"
	download ${curr_spl} ${out_dir} && rename ${curr_spl} ${out_dir}
	for curr_clean in "${samples_to_clean[@]}" ; do
		if [ ${curr_spl} == ${curr_clean} ] ; then
			echo "    > Cut ${curr_spl}"
			cutseq ${curr_spl} ${out_dir}
		fi
	done
done

conda deactivate

echo "End of job"
