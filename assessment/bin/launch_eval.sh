#!/bin/bash
# author = Frederic Escudie
# copyright = Copyright (C) 2020 IUCT-O
# license = GNU General Public License
# version = 1.1.0

# Parameters and environment
if [ $# -eq 0 ]
then
    echo -e "[\033[0;31mERROR\033[0m] The workflow version is required"
    exit 1
fi
wf_version=$1

assessment_bin_dir=`dirname $0`
assessment_bin_dir=`realpath ${assessment_bin_dir}`
assessment_dir=`dirname ${assessment_bin_dir}`
export PATH=${assessment_bin_dir}:$PATH

# Evaluate datasets
declare -a datasets=('Heyer_2019' 'Tembe_2014' 'simulated')
for dataset in "${datasets[@]}"
do
	echo "Process "${dataset_name}
	evalVCFRes.py \
	 -d ${dataset} \
	 -m genes \
     -i ${assessment_dir}/../config/filters_rules.json \
	 -e ${assessment_dir}/datasets/${dataset}_fusions_list.tsv \
	 -a ${assessment_dir}/results/${wf_version}/${dataset}/vcf/*_unfiltered.vcf \
	 -o ${assessment_dir}/results/${wf_version}/${dataset}/results_genes.tsv
    if [ $? -ne 0 ]; then
 		>&2 echo "Error in evalVCFRes genes"
 		exit 1
 	fi
	evalVCFRes.py \
	 -d ${dataset} \
	 -m breakpoints \
     -i ${assessment_dir}/../config/filters_rules.json \
	 -e ${assessment_dir}/datasets/${dataset}_fusions_list.tsv \
	 -a ${assessment_dir}/results/${wf_version}/${dataset}/vcf/*_unfiltered.vcf \
	 -o ${assessment_dir}/results/${wf_version}/${dataset}/results_breakpoints.tsv
    if [ $? -ne 0 ]; then
  		>&2 echo "Error in evalVCFRes breakpoints"
  		exit 1
  	fi
done

# Concatenate all datasets
egrep --no-filename "^dataset\ssample_ID" ${assessment_dir}/results/${wf_version}/*/results_genes.tsv | uniq > ${assessment_dir}/results/${wf_version}/results_details_genes.tsv && \
egrep --no-filename -v "^dataset\ssample_ID" ${assessment_dir}/results/${wf_version}/*/results_genes.tsv >> ${assessment_dir}/results/${wf_version}/results_details_genes.tsv && \
egrep --no-filename --no-filename "^dataset\ssample_ID" ${assessment_dir}/results/${wf_version}/*/results_breakpoints.tsv | uniq > ${assessment_dir}/results/${wf_version}/results_details_breakpoints.tsv && \
egrep -v "^dataset\ssample_ID" ${assessment_dir}/results/${wf_version}/*/results_breakpoints.tsv >> ${assessment_dir}/results/${wf_version}/results_details_breakpoints.tsv
if [ $? -ne 0 ]; then
    >&2 echo "Error in merge results"
    exit 1
fi

# Process performance metrics
evalVCFMetrics.py \
 -i ${assessment_dir}/results/${wf_version}/results_details_genes.tsv \
 -o ${assessment_dir}/results/${wf_version}/results_metrics_genes.tsv
if [ $? -ne 0 ]; then
    >&2 echo "Error in evalVCFMetrics genes"
    exit 1
fi
evalVCFMetrics.py \
 -i ${assessment_dir}/results/${wf_version}/results_details_breakpoints.tsv \
 -o ${assessment_dir}/results/${wf_version}/results_metrics_breakpoints.tsv
if [ $? -ne 0 ]; then
    >&2 echo "Error in evalVCFMetrics breakpoints"
    exit 1
fi

echo "End of job"
