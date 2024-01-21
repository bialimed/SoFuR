__author__ = 'Frederic Escudie and Veronique Ivashchenko'
__copyright__ = 'Copyright (C) 2019 CHU Toulouse'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'

from lib.utils import *


########################################################################
#
# Logging
#
########################################################################
wf_name = "SoFuR"
wf_version = __version__
onstart:
    print(getLogMessage(
        wf_name,
        "\033[34mStart\033[0m workflow on version: {}".format(wf_version)
    ))

onsuccess:
    print(getLogMessage(
        wf_name,
        "Workflow completed \033[92msuccessfully\033[0m"
    ))

onerror:
    print(getLogMessage(
        wf_name,
        "Execution \033[91mfailure\033[0m",
        "ERROR"
    ))


########################################################################
#
# Set parameters
#
########################################################################
SAMPLES = None
if config.get("samples") is not None:
    SAMPLES = config["samples"]
else:
    SAMPLES = [elt[:-2] for elt in commonSubPaths(config.get("R1"), config.get("R2"), True)]
R1_PATTERN = config["R1"][0].replace(SAMPLES[0], "{sample}")
R2_PATTERN = config["R2"][0].replace(SAMPLES[0], "{sample}")
CALLERS = ["manta", "STAR_Fusion", "Arriba"]
non_vcf_caller_constraint = {"caller": "({})".format("|".join(set(CALLERS) - {"manta"}))}


########################################################################
#
# Process
#
########################################################################
include: "rules/all.smk"
rule all:
    input:
        expand("report/{sample}.html", sample=SAMPLES),
        "report/run.html",
        "stats/multiqc/multiqc_report.html"

# Run info
if config.get("run_folder") is not None:
    run_folder = config.get("run_folder")
    interopSummary(
        in_interop_folder=os.path.join(run_folder, "InterOp"),
        out_summary="report/data/interopSummary.json",
        out_stderr="logs/interop/interopSummary_stderr.txt",
        params_keep_outputs=True
    )
    illuRunInfoToJSON(
        in_run_folder=run_folder,
        out_summary="report/data/runSummary.json",
        out_stderr="logs/interop/runSummary_stderr.txt",
        params_keep_outputs=True
    )

# Cleaning
cutadapt_pe(
    in_R1_reads=R1_PATTERN,
    in_R2_reads=R2_PATTERN,
    in_R1_end_adapter=config.get("cleaning")["R1_end_adapter"],
    in_R2_end_adapter=config.get("cleaning")["R2_end_adapter"],
    params_error_rate=config.get("cleaning")["adapter_error_rate"],
    params_min_length=config.get("cleaning")["reads_min_length"],
    params_min_overlap=config.get("cleaning")["adapter_min_overlap"]
)

# Fusions calling
arriba(
    in_annotations=config.get("reference")["annotations"],
    in_blacklist=config.get("fusions_calling")["arriba_blacklist"],
    in_reference_seq=config.get("reference")["sequences"],
    params_disabled_filters=["many_spliced", "mismatches", "pcr_fusions"]
)
manta(
    in_annotations=config.get("reference")["annotations"],
    in_reference_seq=config.get("reference")["sequences"],
    out_sv="structural_variants/manta/{sample}_fusions.vcf",
    params_is_somatic=config.get("fusions_calling")["is_somatic"],
    params_is_stranded=True
)
starFusion(
    in_genome_dir=config.get("reference")["STAR-Fusion"],
    in_R1="cutadapt/{sample}_R1.fastq.gz",
    in_R2="cutadapt/{sample}_R2.fastq.gz"
)
if not config.get("reference")["without_chr"]:
    fusionsToVCF(
        out_fusions="structural_variants/{caller}/{sample}_fusions_unstd.vcf",
        snake_wildcard_constraints=non_vcf_caller_constraint
    )
else:
    fusionsToVCF(
        out_fusions="structural_variants/{caller}/{sample}_fusions.vcf.tmp",
        snake_wildcard_constraints=non_vcf_caller_constraint
    )
    renameChromVCF(
        in_variants="structural_variants/{caller}/{sample}_fusions.vcf.tmp",
        out_variants="structural_variants/{caller}/{sample}_fusions_unstd.vcf",
        out_stderr="logs/{sample}_{caller}_renameChr_stderr.txt",
        snake_wildcard_constraints=non_vcf_caller_constraint
    )
standardizeBND(
    in_reference_seq=config.get("reference")["sequences"],
    in_variants="structural_variants/{caller}/{sample}_fusions_unstd.vcf",
    out_variants="structural_variants/{caller}/{sample}_fusions.vcf",
    snake_wildcard_constraints=non_vcf_caller_constraint
)
mergeVCFFusionsCallers(
    in_variants=["structural_variants/" + curr_caller + "/{sample}_fusions.vcf" for curr_caller in CALLERS],
    params_annotation_field="FCANN",
    params_calling_sources=CALLERS,
    params_shared_filters=["Imprecise"]
)

# Fusions annotation
annotBND(
    in_annotations=config.get("reference")["annotations"],
    in_variants="structural_variants/{sample}.vcf",
    out_variants="structural_variants/{sample}_annot.vcf"
)
annotKnownBND(
    in_known_partners=config.get("reference")["known_partners"],
    in_variants="structural_variants/{sample}_annot.vcf",
    out_variants="structural_variants/{sample}_annot_known.vcf"
)

# Fusions pathogenicity
#########################

# Filters
filterBND(
    in_annotations=config.get("reference")["annotations"],
    in_normal=config.get("reference")["healthy_partners"].get("paths", None),
    in_variants="structural_variants/{sample}_annot_known.vcf",
    out_variants="structural_variants/{sample}_unfiltered.vcf",
    params_min_support=config.get("filters")["low_support"],
    params_normal_sources=config.get("reference")["healthy_partners"].get("description", None),
    params_normal_key="symbol",
    params_keep_outputs=True
)
filterAnnotVCF(
    in_filters_variants=config.get("filters")["rules"],
    in_variants="structural_variants/{sample}_unfiltered.vcf",
    out_variants="structural_variants/{sample}_filtered.vcf",
    out_stderr="logs/{sample}_filterVCF_stderr.txt",
    params_keep_outputs=True
)

# Report
inspectBND(
    in_alignments="structural_variants/manta/{sample}Aligned.sortedByCoord.out_markdup.bam",
    in_annotations=config.get("reference")["annotations"],
    in_domains=config.get("reference")["domains_annotations"],
    in_targets=config.get("protocol", {}).get("targets"),
    in_variants="structural_variants/{sample}_filtered.vcf",
    out_annotations="report/data/{sample}_fusions_inspect.json",
    params_keep_outputs=True
)
fusionsToJSON(
    out_variants="report/data/{sample}_fusions_filtered.json",
    params_assembly_id=config.get("reference")["assembly"],
    params_merged_sources=True,
    params_calling_source="",
    params_keep_outputs=True
)
wfReport(
    in_interop_summary=("report/data/interopSummary.json" if config.get("run_folder") else None),
    in_run_summary=("report/data/runSummary.json" if config.get("run_folder") else None),
    params_samples=SAMPLES
)
# Quality report
fastqc(
    in_fastq=R1_PATTERN.replace("_R1", "{suffix}"),
    params_is_grouped=False
)
insertSize(
    in_alignments="structural_variants/manta/{sample}Aligned.sortedByCoord.out_markdup.bam",
    out_metrics="stats/insert_size/{sample}.tsv",
    out_report="stats/insert_size/{sample}.pdf",
    out_stderr="logs/picard/{sample}_insertSize_stderr.txt"
)
rseqc_readDistribution(
    in_annotations=config.get("reference")["genes_bed"],
    in_alignments="structural_variants/manta/{sample}Aligned.sortedByCoord.out_markdup.bam",
    out_metrics="stats/reseqc/read_distribution/{sample}.tsv"
)
rseqc_inferExperiment(
    in_annotations=config.get("reference")["genes_bed"],
    in_alignments="structural_variants/manta/{sample}Aligned.sortedByCoord.out_markdup.bam",
    out_metrics="stats/reseqc/infer_experiment/{sample}.tsv"
)
FASTQC_PATTERN = "stats/fastqc/" + os.path.basename(R1_PATTERN.replace("_R1", "{suffix}").replace(".fastq.gz", "_fastqc.html").replace(".fastq", "_fastqc.html"))
FASTQC_PATTERN = FASTQC_PATTERN[:-4] + "zip"
multiqc(
    in_files=(
        expand(FASTQC_PATTERN, sample=SAMPLES, suffix=["_R1", "_R2"]) +
        expand("stats/cutadapt/{sample}.txt", sample=SAMPLES) +
        expand("structural_variants/manta/{sample}Log.final.out", sample=SAMPLES) +
        expand("structural_variants/manta/{sample}Aligned.sortedByCoord.out_markdup.bam.tsv", sample=SAMPLES) +
        expand("stats/insert_size/{sample}.tsv", sample=SAMPLES) +
        expand("stats/reseqc/read_distribution/{sample}.tsv", sample=SAMPLES) +
        expand("stats/reseqc/infer_experiment/{sample}.tsv", sample=SAMPLES)
    )
)
