__author__ = 'Frederic Escudie and Veronique Ivashchenko'
__copyright__ = 'Copyright (C) 2019 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '0.3.0'
__email__ = 'escudie.frederic@iuct-oncopole.fr'
__status__ = 'dev'

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
    SAMPLES = [elt[:-2] for elt in commonSubPathes(config.get("R1"), config.get("R2"), True)]
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
        expand("structural_variants/{sample}_filtered.vcf", sample=SAMPLES),
        expand("structural_variants/{sample}_unfiltered.vcf", sample=SAMPLES),
        expand("report/data/{sample}_fusions_filtered.json", sample=SAMPLES), ########################
        "stats/multiqc/multiqc_report.html"

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
    params_disabled_filters=["many_spliced", "mismatches", "pcr_fusions"],
    params_nb_threads=config.get("fusions_calling")["STAR_nb_threads"],
    params_sort_memory=8
)
manta(
    in_annotations=config.get("reference")["annotations"],
    in_reference_seq=config.get("reference")["sequences"],
    out_sv="structural_variants/manta/{sample}_fusions.vcf",
    params_is_somatic=config.get("fusions_calling")["is_somatic"],
    params_is_stranded=True,
    params_nb_threads=config.get("fusions_calling")["STAR_nb_threads"],
    params_sort_memory=8
)
starFusion(
    in_genome_dir=config.get("reference")["STAR-Fusion"],
    in_R1="cutadapt/{sample}_R1.fastq.gz",
    in_R2="cutadapt/{sample}_R2.fastq.gz",
    params_nb_threads=config.get("fusions_calling")["STAR_nb_threads"]
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

# Fusions pathogenicity
#########################

# Filters
bodymap = os.path.join(config.get("reference")["fusionCatcher"], "bodymap2.txt")
babiceanu = os.path.join(config.get("reference")["fusionCatcher"], "non-cancer_tissues.txt")
filterBND(
    in_annotations=config.get("reference")["annotations"],
    in_normal=[bodymap, babiceanu],
    in_variants="structural_variants/{sample}_annot.vcf",
    out_variants="structural_variants/{sample}_unfiltered.vcf",
    params_normal_sources="Illumina Body Map 2 and Babiceanu et al NAR 2016",
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
fusionsToJSON(
    out_variants="report/data/{sample}_fusions_filtered.json",
    params_assembly_id=config.get("reference")["assembly"],
    params_merged_sources=True,
    params_calling_source="",
    params_keep_outputs=True
)
wfReport(params_samples=SAMPLES)
# Quality report
fastqc(
    in_fastq=R1_PATTERN.replace("_R1", "{suffix}"),
    params_is_grouped=False
)
rseqc_readDistribution(
    in_annotations=config.get("reference")["genes_bed"],
    in_alignments="structural_variants/manta/{sample}Aligned.sortedByCoord.out_markdup.bam",
    out_metrics="stats/reseqc/read_distribution/{sample}.tsv"
)
FASTQC_PATTERN = "stats/fastqc/" + os.path.basename(R1_PATTERN.replace("_R1", "{suffix}").replace(".fastq.gz", "_fastqc.html").replace(".fastq", "_fastqc.html"))
FASTQC_PATTERN = FASTQC_PATTERN[:-4] + "zip"
multiqc(
    in_files=(
        expand(FASTQC_PATTERN, sample=SAMPLES, suffix=["_R1", "_R2"]) +
        expand("stats/cutadapt/{sample}.txt", sample=SAMPLES) +
        expand("structural_variants/manta/{sample}Log.final.out", sample=SAMPLES) +
        expand("structural_variants/manta/{sample}Aligned.sortedByCoord.out_markdup.bam.tsv", sample=SAMPLES) +
        expand("stats/reseqc/read_distribution/{sample}.tsv", sample=SAMPLES)
    )
)
