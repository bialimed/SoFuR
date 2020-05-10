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
	mv $1_1.fastq.gz $2_R1.fastq.gz && mv $1_2.fastq.gz $2_R2.fastq.gz
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
	"SRR3380691"
	"SRR3380690"
	"SRR6796292"
	"SRR6796293"
	"SRR3380693"
	"SRR3380692"
	"SRR3380694"
	"SRR3380695"
	"SRR6796329"
	"SRR6796328"
	"SRR3380701"
	"SRR3380700"
	"SRR3380702"
	"SRR3380703"
	"SRR3380704"
	"SRR3380705"
	"SRR6796334"
	"SRR6796335"
	"SRR6796352"
	"SRR6796353"
	"SRR6796358"
	"SRR6796359"
	"SRR6796361"
	"SRR6796360"
	"SRR6796362"
	"SRR6796363"
	"SRR6796365"
	"SRR6796364"
	"SRR6796367"
	"SRR6796366"
	"SRR6796368"
	"SRR6796369"
	"SRR6796370"
	"SRR6796371"
	"SRR6796380"
	"SRR6796381"
	"SRR6796286"
	"SRR6796287"
	"SRR6796296"
	"SRR6796297"
	"SRR6796298"
	"SRR6796299"
	"SRR6796300"
	"SRR6796301"
	"SRR6796302"
	"SRR6796303"
	"SRR6796310"
	"SRR6796311"
	"SRR6796316"
	"SRR6796317"
	"SRR6796324"
	"SRR6796325"
	"SRR6796330"
	"SRR6796331"
	"SRR6796295"
	"SRR6796294"
	"SRR3380714"
	"SRR3380713"
	"SRR3380716"
	"SRR3380715"
	"SRR3380717"
	"SRR3380718"
	"SRR6796338"
	"SRR6796339"
	"SRR3380720"
	"SRR3380719"
	"SRR3380721"
	"SRR3380722"
	"SRR3380723"
	"SRR3380724"
	"SRR6796280"
	"SRR6796281"
	"SRR6796285"
	"SRR6796284"
	"SRR6796312"
	"SRR6796313"
	"SRR6796315"
	"SRR6796314"
	"SRR6796322"
	"SRR6796323"
	"SRR064438"
	"SRR064439"
	"SRR064440"
	"SRR064441"
	"SRR064287"
	"SRR064286"
	"SRR018266"
	"SRR018259"
	"SRR018267"
	"SRR018265"
	"SRR018261"
	"SRR018260"
	"SRR7646928"
	"SRR7646929"
	"SRR7646934"
	"SRR7646935"
	"SRR7646932"
	"SRR7646933"
	"SRR7646936"
	"SRR7646937"
	"SRR7646890"
	"SRR7646896"
	"SRR7646902"
	"SRR7646898"
	"SRR7646901"
	"SRR7646906"
	"SRR7646907"
	"SRR7646952"
	"SRR7646955"
	"SRR7646948"
	"SRR7646951"
	"SRR7646885"
	"SRR7646882"
	"SRR7646883"
	"SRR7646942"
	"SRR7646959"
	"SRR7646961"
	"SRR7646962"
	"SRR7646963"
	"SRR7646965"
	"SRR7646966"
	"SRR7646967"
	"SRR7646919"
)

for curr_spl in ${samples}
do
	echo "Download ${curr_spl} in ${out_dir}"
	download ${curr_spl} ${out_dir} && rename ${curr_spl}
done

echo "End of job"
