# SoFuR: SOmatic FUsions from Rna | STraDA: Somatic TRAnslocation from strandeD rnA

![license](https://img.shields.io/badge/license-GPLv3-blue)

## Description
This workflow detects, annotates and filters somatic fusions from stranded
paired-end RNA-seq from Illumina's instruments.

## Workflow steps
![Missing image](doc/img/workflow.png)

## Installation

## Usage
    snakemake \
      --use-conda \
      --conda-prefix ${application_env} \
      --jobs ${nb_jobs} \
      --latency-wait 100 \
      --snakefile ${application_dir}/Snakefile \
      --cluster-config ${application_dir}/config/cluster.json \
      --configfile cfg.yml \ # See template ${application_dir}/config/workflow_parameters.yml
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
list and annotations are in `out_dir/report/{sample}.html`.
* The quality reports is in `out_dir/stats/multiqc/multiqc_report.html`. It
resumes qualities of reads, distribution of alignments (between exon, intron,
...) and strandness analysis.
* The annotated fusions in VCF format are kept in `out_dir/structural_variants`.
`*_unfiltered.vcf` contain all the fusions, their annotations and their tags.
`*_filtered.vcf` contain all the fusions, their annotations and their tags after
filtering by rules provided by file declarated in configfile by `filters.rules`.


## Copyright
2019 Laboratoire d'Anatomo-Cytopathologie de l'Institut Universitaire du Cancer
Toulouse - Oncopole

## Contact
escudie.frederic@iuct-oncopole.fr
