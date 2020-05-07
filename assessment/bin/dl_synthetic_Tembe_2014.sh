#!/bin/bash

# Download SRA samples from synthetic dataset Tembe et al.,2014 
download () {
	fastq-dump --split-files --gzip --outdir /Anapath/veronique/SRA $1
	if [ $? -ne 0 ]; then
		>&2 echo "Error on $1"
		exit 1
	fi
}


#~ download "SRR1659960" ; rename.sh SRR1659960 ##################### Problem in file download
#~ download "SRR1659966" ; rename.sh SRR1659966 ##################### Problem in file download
download "SRR1659951" ; rename.sh SRR1659951
download "SRR1659952" ; rename.sh SRR1659952
download "SRR1659953" ; rename.sh SRR1659953
download "SRR1659954" ; rename.sh SRR1659954
download "SRR1659959" ; rename.sh SRR1659959
download "SRR1659955" ; rename.sh SRR1659955
download "SRR1659956" ; rename.sh SRR1659956
download "SRR1659957" ; rename.sh SRR1659957
download "SRR1659958" ; rename.sh SRR1659958
download "SRR1548811" ; rename.sh SRR1548811
download "SRR1659961" ; rename.sh SRR1659961
download "SRR1659962" ; rename.sh SRR1659962
download "SRR1659963" ; rename.sh SRR1659963
download "SRR1659968" ; rename.sh SRR1659968
download "SRR1659964" ; rename.sh SRR1659964
download "SRR1659965" ; rename.sh SRR1659965
download "SRR1659967" ; rename.sh SRR1659967
download "SRR1544075" ; rename.sh SRR1544075
echo "End of job"
