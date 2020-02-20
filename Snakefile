__author__ = 'Frederic Escudie and Veronique Ivashchenko'
__copyright__ = 'Copyright (C) 2019 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '0.1.0'
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
# Samples
SAMPLES = None
if config.get("samples") is not None:
    SAMPLES = config["samples"]
else:
    SAMPLES = [elt[:-2] for elt in commonSubPathes(config.get("R1"), config.get("R2"), True)]
R1_PATTERN = config["R1"][0].replace(SAMPLES[0], "{sample}")
R2_PATTERN = config["R2"][0].replace(SAMPLES[0], "{sample}")


########################################################################
#
# Process
#
########################################################################
include: "rules/all.smk"
rule all:
    input:
        expand("structural_variants/{caller}/{sample}_fusions.vcf", sample=SAMPLES, caller=["STAR_Fusion", "Arriba", "FusionCatcher", "manta"])

fastqc(
    in_fastq=R1_PATTERN.replace("_R1", "{suffix}"),
    params_is_grouped=False
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
fusionCatcher(
    in_R1=R1_PATTERN,
    in_R2=R2_PATTERN,
    in_fusion_resources=config.get("reference")["fusionCatcher"],
    params_nb_threads=config.get("fusions_calling")["STAR_nb_threads"],
    params_keep_outputs=True  # ###############################################
)
arriba(
    in_annotations=config.get("reference")["annotations"],
    in_blacklist=config.get("fusions_calling")["arriba_blacklist"],
    in_reference_seq=config.get("reference")["sequences"],
    params_disabled_filters=["many_spliced", "mismatches", "pcr_fusions"],
    params_nb_threads=config.get("fusions_calling")["STAR_nb_threads"],
    params_keep_outputs=True  # ###############################################
)
manta(
    in_annotations=config.get("reference")["annotations"],
    in_reference_seq=config.get("reference")["sequences"],
    out_sv="structural_variants/manta/{sample}_fusions.vcf",
    params_is_somatic=config.get("fusions_calling")["is_somatic"],
    params_is_stranded=config.get("fusions_calling")["is_stranded"],
    params_nb_threads=config.get("fusions_calling")["STAR_nb_threads"],
    params_keep_outputs=True  # ###############################################
)
starFusion(
    in_genome_dir=config.get("reference")["STAR-Fusion"],
    in_R1="cutadapt/{sample}_R1.fastq.gz",
    in_R2="cutadapt/{sample}_R2.fastq.gz",
    params_nb_threads=config.get("fusions_calling")["STAR_nb_threads"],
    params_keep_outputs=True  # ###############################################
)
fusionsToVCF(
    params_keep_outputs=True  # ###############################################
)

# Fusions annotation
