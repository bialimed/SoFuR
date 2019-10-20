#
# Copyright (C) 2019 IUCT-O
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

__author__ = 'Frederic Escudie'
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
wf_name = "fusion"
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
# Rules parameters
_rule_kwargs = {}

# Samples
SAMPLES = None
if config.get("samples") is not None:
    SAMPLES = config["samples"]
else:
    SAMPLES = [elt[:-2] for elt in commonSubPathes(config.get("R1"), config.get("R2"), True)]
R1_PATTERN = config["R1"][0].replace(SAMPLES[0], "{sample}")
R2_PATTERN = config["R2"][0].replace(SAMPLES[0], "{sample}")

# Others
VARIANTS_CALLERS = ["manta", "fusionCatcher"]


########################################################################
#
# Process
#
########################################################################
rule all:
    input:
        expand("structural_variants/{variant_caller}/{sample}_SV_annot.vcf", sample=SAMPLES, variant_caller=VARIANTS_CALLERS)

# Variant calling fusionCatcher
fusionCatcher_kwargs = {
    "in.R1": R1_PATTERN,
    "in.R2": R2_PATTERN,
    "in.fusion_data": config["reference"]["fusionsCatcher"]
}
include: "rules/fusionCatcher.smk"

# Variant calling manta
# cutadapt_kwargs
# include: "rules/cutadapt.smk"
star_kwargs = {
    "in.R1": R1_PATTERN,
    "in.R2": R2_PATTERN,
    "in.reference_seq": config["reference"]["sequences"],
    "in.annotations": config["reference"]["annotations"],
    "params.extra": " --outSJfilterCountUniqueMin -1 2 2 2"
                    " --outSJfilterCountTotalMin -1 2 2 2"
                    " --outFilterType BySJout"
                    " --outFilterIntronMotifs RemoveNoncanonical"
                    " --chimSegmentMin 15"
                    " --chimJunctionOverhangMin 15"
                    " --chimScoreDropMax 20"
                    " --chimScoreSeparation 10"
                    " --chimOutType WithinBAM"
                    " --chimSegmentReadGapMax 5"
                    " --twopassMode Basic"
}
include: "rules/star.smk"
include: "rules/markDuplicates.smk"
manta_kwargs = {"in.sequences": config["reference"]["sequences"], "params.type": "rna"}
include: "rules/manta.smk"

# Annotate fusions
include: "rules/annotBND.smk"
