#!/bin/bash
set -e # exit when any command fails

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
declare -a datasets=('Heyer_2019', 'Tembe_2014', 'simulated')
for dataset in "${datasets[@]}"
do
	echo "Process "${dataset_name}
	evalVCFRes.py \
	 -d ${dataset} \
	 -m genes \
     -i ../../config/filters_rules.json \
	 -e datasets/${dataset}_fusions_list.tsv \
	 -a results/${wf_version}/${dataset}/vcf/*_unfiltered.vcf \
	 -o results/${wf_version}/${dataset}/results_genes.tsv
	evalVCFRes.py \
	 -d ${dataset} \
	 -m breakpoints \
     -i ../../config/filters_rules.json \
	 -e datasets/litterature_expected_fusion_list.tsv \
	 -a results/${wf_version}/${dataset}/vcf/*_unfiltered.vcf \
	 -o results/${wf_version}/${dataset}/results_breakpoints.tsv
done

# Concatenate all datasets
grep "dataset\tsample_ID" results/${wf_version}/Heyer_2019/results_genes.tsv > results/${wf_version}/results_details_genes.tsv
grep -v "dataset\tsample_ID" results/${wf_version}/*/results_genes.tsv >> results/${wf_version}/results_details_genes.tsv

grep "dataset\tsample_ID" results/${wf_version}/Heyer_2019/results_breakpoints.tsv > results/${wf_version}/results_details_breakpoints.tsv
grep -v "dataset\tsample_ID" results/${wf_version}/*/results_breakpoints.tsv >> results/${wf_version}/results_details_breakpoints.tsv

# Process performance metrics
evalVCFMetrics.py \
 -i results/${wf_version}/results_details_genes.tsv \
 -o results/${wf_version}/results_metrics_genes.tsv
evalVCFMetrics.py \
 -i results/${wf_version}/results_details_breakpoints.tsv \
 -o results/${wf_version}/results_metrics_breakpoints.tsv

echo "End of job"
