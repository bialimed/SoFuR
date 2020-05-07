#!/bin/bash

# Download SRA samples litterature tumour dataset Heyer et al.,2019
download () {
	fastq-dump --split-files --gzip --outdir /Anapath/veronique/SRA $1
	if [ $? -ne 0 ]; then
		>&2 echo "Error on $1"
		exit 1
	fi
}

#~ download "SRR7646937" ; rename.sh SRR7646937 ##################### Problem in file download (more reads in file 2 than in file 1)
#~ download "SRR7646901" ; rename.sh SRR7646901 ##################### Fusion not verified by other method
#~ download "SRR7646885" ; rename.sh SRR7646885 ##################### Fusion not verified by other method
#~ download "SRR7646959" ; rename.sh SRR7646959 ##################### Problem in file download (more reads in file 1 than in file 2)
download "SRR7646928" ; rename.sh SRR7646928
download "SRR7646929" ; rename.sh SRR7646929
download "SRR7646934" ; rename.sh SRR7646934
download "SRR7646935" ; rename.sh SRR7646935
download "SRR7646932" ; rename.sh SRR7646932
download "SRR7646933" ; rename.sh SRR7646933
download "SRR7646936" ; rename.sh SRR7646936
download "SRR7646890" ; rename.sh SRR7646890
download "SRR7646896" ; rename.sh SRR7646896
download "SRR7646902" ; rename.sh SRR7646902
download "SRR7646898" ; rename.sh SRR7646898
download "SRR7646906" ; rename.sh SRR7646906
download "SRR7646907" ; rename.sh SRR7646907
download "SRR7646952" ; rename.sh SRR7646952
download "SRR7646955" ; rename.sh SRR7646955
download "SRR7646948" ; rename.sh SRR7646948
download "SRR7646951" ; rename.sh SRR7646951
download "SRR7646882" ; rename.sh SRR7646882
download "SRR7646883" ; rename.sh SRR7646883
download "SRR7646942" ; rename.sh SRR7646942
download "SRR7646961" ; rename.sh SRR7646961
download "SRR7646962" ; rename.sh SRR7646962
download "SRR7646963" ; rename.sh SRR7646963
download "SRR7646965" ; rename.sh SRR7646965
download "SRR7646966" ; rename.sh SRR7646966
download "SRR7646967" ; rename.sh SRR7646967
download "SRR7646919" ; rename.sh SRR7646919
echo "End of job"
