#!/bin/bash
# author = Frederic Escudie
# copyright = Copyright (C) 2020 IUCT-O
# license = GNU General Public License
# version = 1.1.0

# Parameters
if [ $# -ne 3 ]
then
    echo -e "[\033[0;31mERROR\033[0m] in arguments: $0 wf_version conda_env_dir work_dir"
    exit 1
fi
wf_version=$1
conda_env_dir=$2
work_dir=$3
assessment_bin_dir=`dirname $0`
assessment_bin_dir=`realpath ${assessment_bin_dir}`
assessment_dir=`dirname ${assessment_bin_dir}`
app_dir=`dirname ${assessment_dir}`

# Environment
unset PYTHONPATH
export PATH=${assessment_bin_dir}:$PATH
export DRMAA_LIBRARY_PATH=$SGE_ROOT/lib/linux-rhel7-x64/libdrmaa.so

# Process wf
declare -a datasets=('Heyer_2019' 'Tembe_2014' 'simulated')
for dataset in "${datasets[@]}"
do
	echo "Process "${dataset}
    mkdir -p ${work_dir}/${dataset} && \
    mkdir -p ${assessment_dir}/results/${wf_version}/${dataset} && \
    source ${conda_env_dir}/../bin/activate && \
    snakemake \
      --use-conda \
      --jobs 50 \
      --latency-wait 100 \
      --drmaa " -V -q normal -l pri_normal=1 -l mem={cluster.vmem} -pe smp {cluster.threads}" \
      --conda-prefix ${conda_env_dir} \
      --cluster-config ${app_dir}/config/cluster.json \
      --snakefile ${app_dir}/Snakefile \
      --configfile ${assessment_dir}/datasets/cfg/${wf_version}/${dataset}_wf_cfg.yml \
      --directory ${work_dir}/${dataset} \
      --printshellcmd \
     > ${work_dir}/${dataset}/wf_log.txt \
     2> ${work_dir}/${dataset}/wf_stderr.txt && \
    mv ${work_dir}/${dataset}/structural_variants/*_unfiltered.vcf ${assessment_dir}/results/${wf_version}/${dataset} && \
    rm -r ${work_dir}/${dataset}
    if [ $? -ne 0 ]; then
        >&2 echo "Error in workflow execution for "${dataset}
        exit 1
    fi
done
echo "End of job"
