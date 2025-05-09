# SoFuR: SOmatic FUsions from Rna

![license](https://img.shields.io/badge/license-GPLv3-blue)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.15376175.svg)](https://doi.org/10.5281/zenodo.15376175)

## Table of Contents
* [Description](#description)
* [Workflow steps](#workflow-steps)
* [Installation](#installation)
* [Usage](#usage)
* [Outputs directory](#outputs-directory)
* [Performances](#performances)
* [Copyright](#copyright)
* [Contact](#contact)

## Description
This workflow detects, annotates and filters somatic fusions from **stranded**
paired-end RNA-seq from Illumina's instruments.

## Workflow steps
![workflow](doc/img/workflow.png)

## Installation
### 1. Download code

      git clone [--branch ${VESRSION}] --recurse-submodules git@github.com:bialimed/sofur.git

### 2. Install dependencies
* conda (>=4.6.8):

      # Install conda
      wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
      sh Miniconda3-latest-Linux-x86_64.sh

      # Install mamba
      conda activate base
      conda install -c conda-forge mamba

  More details on miniconda install [here](https://docs.conda.io/en/latest/miniconda.html).

* snakemake (>=5.4.2):

      mamba create -c conda-forge -c bioconda -n sofur snakemake==7.32.4
      conda activate sofur
      pip install drmaa

  More details on snakemake install [here](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

* Install rules dependencies (cutadapt, bwa, ...):

      conda activate sofur
      snakemake \
        --use-conda \
        --conda-prefix ${application_env_dir} \
        --conda-create-envs-only
        --snakefile ${APP_DIR}/Snakefile \
        --configfile workflow_parameters.yml

### 4. Download and prepare resources
SoFuR uses genome sequences, genes annotations, known fusions databanks (artifacts
and pathogenics) and others standard resources. These files must be provided in
your config.yml (see [template](config/workflow_parameters.tpl.yml)).
An detailed example for the creation process of these resources is available
[here](doc/prepare_databanks.md).

### 5. Test install
* From `${APP_DIR}/test/config/wf_config.yml` set variables corresponding to
databanks (see `## ${BANK}/... ##`).

* Launch test wit following command:

      conda activate sofur
      ${APP_DIR}/test/launch_wf.sh \
        ${CONDA_ENVS_DIR} \
        ${WORK_DIR} \
        ${DRMAA_PARAMS}

  Example with scheduler SGE:

      export DRMAA_LIBRARY_PATH=${SGE_ROOT}/lib/linux-rhel7-x64/libdrmaa.so

      conda activate sofur
      ~/soft/sofur/test/launch_wf.sh \
        /work/$USER/conda_envs/envs \
        /work/$USER/test_sofur \
        ' -V -q {cluster.queue} -l pri_{cluster.queue}=1 -l mem={cluster.vmem} -l h_vmem={cluster.vmem} -pe smp {cluster.threads}'

  Example with scheduler slurm:

      export DRMAA_LIBRARY_PATH=$SGE_ROOT/lib/linux-rhel7-x64/libdrmaa.so

      conda activate sofur
      ~/soft/sofur/test/launch_wf.sh \
        /work/$USER/conda_envs/envs \
        /work/$USER/test_sofur \
        ' --partition={cluster.queue} --mem={cluster.mem} --cpus-per-task={cluster.threads}'

* See results in `${WORK_DIR}/report/run.html`.

## Usage
Copy `${APP_DIR}/config/workflow_parameters.tpl.yml` in your current directory
and change values before launching the following command:

    conda activate sofur
    snakemake \
      --use-conda \
      --conda-prefix ${application_env_dir} \
      --jobs ${nb_jobs} \
      --jobname "sofur.{rule}.{jobid}" \
      --latency-wait 100 \
      --snakefile ${application_dir}/Snakefile \
      --cluster-config ${application_dir}/config/cluster.json \
      --configfile workflow_parameters.yml \
      --directory ${out_dir} \
      > ${out_dir}/wf_log.txt \
      2> ${out_dir}/wf_stderr.txt

## Outputs directory
The main elements of the outputs directory are the following:

    out_dir/
    ├── ...
    ├── report/
    |   ├── ...
    |   ├── run.html
    |   └── sample-A.html
    ├── stats/
    |   ├── ...
    |   └── multiqc/
    |       ├── ...
    |       └── multiqc_report.html
    └── structural_variants/
        ├── ...
        ├── sample-A_unfiltered.vcf
        └── sample-A_filtered.vcf

* The [reports](doc/img/example_EWSR1_FLI1.png) files containing filtered fusions
list, annotations and [viewers](doc/img/example_breakend_viewer.png) are in
`out_dir/report/{sample}.html`.
* The quality reports is in `out_dir/stats/multiqc/multiqc_report.html`. It
resumes qualities of reads, distribution of alignments (between exon, intron,
...) and strandness analysis.
* The annotated fusions in VCF format are kept in `out_dir/structural_variants`.
`*_unfiltered.vcf` contain all the fusions, their annotations and their tags.
`*_filtered.vcf` contain all the fusions, their annotations and their tags after
filtering by rules provided by file declarated in configfile by `filters.rules`.

## Performances
The performances are evaluated on real, synthetic and simulated datasets. The
commands used in evaluation are stored in `assessment`. The results summarized
in [assessment/report.html](assessment/report.html).

## Copyright
2019 Laboratoire d'Anatomo-Cytopathologie du CHU de Toulouse
