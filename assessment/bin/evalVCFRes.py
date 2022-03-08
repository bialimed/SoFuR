#!/usr/bin/env python3

__author__ = 'Veronique Ivashchenko and Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.3.0'
__email__ = 'escudie.frederic@iuct-oncopole.fr'
__status__ = 'prod'

import os
import sys
import json
import argparse
import logging
from itertools import product
from anacore.sv import HashedSVIO
from anacore.fusion import BreakendVCFIO, getStrand
from anacore.filters import filtersFromDict


################################################################################
#
# FUNCTIONS
#
################################################################################
def hasSameCoordinates(fusion, first, second):
    """
    Return True if 1st and 2nd breakend correspond to fusion.

    :param fusion: breakend location for the reference fusion: {"chr1": <v>, "pos1": <v>, "chr2": <v>, "pos2": <v>}.
    :type fusion: dict
    :param first: First breakend in evaluated fusion.
    :type first: anacore.fusion.BreakendVCFIO
    :param second: Second breakend in evaluated fusion.
    :type second: anacore.fusion.BreakendVCFIO
    :return: True if 1st and 2nd breakend correspond to fusion.
    :rtype: bool
    """
    has_same_coord = False
    if first.chrom == fusion["chr1"] and second.chrom == fusion["chr2"]:
        if first.info["ANNOT_POS"] == fusion["pos1"] and second.info["ANNOT_POS"] == fusion["pos2"]:
            has_same_coord = True
        elif "CIPOS" in first.info and "CIPOS" in second.info:  # If match is not exact try to take into account CIPOS
            first_bnd_limit_left = first.pos - abs(first.info["CIPOS"][0])
            first_bnd_limit_right = first.pos + first.info["CIPOS"][1]
            second_bnd_limit_left = second.pos - abs(second.info["CIPOS"][0])
            second_bnd_limit_right = second.pos + second.info["CIPOS"][1]
            if fusion["pos1"] >= first_bnd_limit_left and fusion["pos1"] <= first_bnd_limit_right:
                has_same_coord = False
                if "IMPRECISE" in first.info:  # If fusion is imprecise check only the interval
                    if fusion["pos2"] >= second_bnd_limit_left and fusion["pos2"] <= second_bnd_limit_right:
                        has_same_coord = True
                else:  # If fusion is precise take into account the CIPOS offset for the two breakends
                    offset_from_left = fusion["pos1"] - first_bnd_limit_left
                    if getStrand(first, True) == getStrand(second, False):
                        if second_bnd_limit_left + offset_from_left == fusion["pos2"]:
                            has_same_coord = True
                    else:
                        if second_bnd_limit_right - offset_from_left == fusion["pos2"]:
                            has_same_coord = True
    return has_same_coord


def getExpected(input_expected):
    """
    Return by sample the expected fusions.

    :param input_expected: Path to file containing the expected fusions (format: TSV).
    Columns required: sample_ID, genes_1, genes_2, chr1, breakpoint1, chr2, breakpoint2;
    For wild-type samples genes_1 = "WT"; For unknown breakpoint breakpoint1 is empty;
    genes_1 contains symbol for coding genes and gene ID for non-coding.
    :type input_expected: str
    :return: By sample a dict of expected fusions: key = gene1<tab>gene2; value = None with unknown breakpoint or dict {"chr1": <v>, "breakpoint1": <v>, "chr2": <v>, "breakpoint2": <v>}.
    :rtype: dict
    """
    expected_by_spl = {}
    with HashedSVIO(input_expected, "r") as reader:
        for record in reader:
            spl = record["sample_ID"]
            if spl not in expected_by_spl:
                expected_by_spl[spl] = dict()
            if record["genes_1"] != "WT":
                fusion = record["genes_1"] + "\t" + record["genes_2"]
                if fusion not in expected_by_spl[spl]:
                    if record["breakpoint1"] == "":  # Positions of breakpoints are not known
                        expected_by_spl[spl][fusion] = None
                    else:
                        expected_by_spl[spl][fusion] = {
                            "chr1": record["chr1"],
                            "pos1": int(record["breakpoint1"]),
                            "chr2": record["chr2"],
                            "pos2": int(record["breakpoint2"])
                        }
    return expected_by_spl


def loadResByCallers(inputs_variants, expected_by_spl, sofur_filters, status_mode="genes", annotation_field="ANN"):
    """
    Return by caller the observed fusions and their status (TP, TP_ISOFORM, FP).

    :param inputs_variants: Path to variants files containing observed fusions (format: VCF).
    :type inputs_variants: str
    :param expected_by_spl: By sample a dict of expected fusions: key = gene1<tab>gene2; value = None with unknown breakpoint or dict {"chr1": <v>, "breakpoint1": <v>, "chr2": <v>, "breakpoint2": <v>}.
    :type expected_by_spl: dict
    :param sofur_filters: Filter rules recommended in SoFuR.
    :type sofur_filters: anacore.filters.FiltersCombiner
    :param status_mode: Type of fusion evaluation: by "genes" partners or by exact "breakpoints".
    :type status_mode: str
    :param annotation_field: Field used to store annotations in VCF.
    :type annotation_field: str
    :return: By caller the observed fusions and their status (TP, TP_ISOFORM, FP).
    :rtype: dict
    """
    res_by_caller = {}
    for curr_vcf in inputs_variants:
        with BreakendVCFIO(curr_vcf, "r", annot_field=annotation_field) as reader:
            curr_spl = reader.samples[0]
            callers_id_desc = reader.info["SRC"].description.split("Possible values: ")[1].replace("'", '"')
            callers = list(json.loads(callers_id_desc).keys()) + ["sofur"]
            # Init with expected
            for curr_src in callers:
                if curr_src not in res_by_caller:
                    res_by_caller[curr_src] = dict()
                if curr_spl in expected_by_spl:
                    res_by_caller[curr_src][curr_spl] = {fusion: list() for fusion in expected_by_spl[curr_spl]}  # init expected in res_by_caller
            # True positives and False positives
            for first, second in reader:
                status = "FP"
                first_genes = {annot["SYMBOL"] if annot["SYMBOL"] else annot["Gene"].split(".")[0] for annot in first.info[annotation_field]}  # symbol for coding and ID for non-coding
                if len(first_genes) == 0:
                    first_genes = {"intergenic"}
                second_genes = {annot["SYMBOL"] if annot["SYMBOL"] else annot["Gene"].split(".")[0] for annot in second.info[annotation_field]}  # symbol for coding and ID for non-coding
                if len(second_genes) == 0:
                    second_genes = {"intergenic"}
                selected_fusion = "unexpected"
                for curr_first_gene, curr_second_gene in product(first_genes, second_genes):
                    curr_fusion = "{}\t{}".format(curr_first_gene, curr_second_gene)
                    if curr_fusion in expected_by_spl[curr_spl]:
                        selected_fusion = curr_fusion
                        if status_mode == "genes":
                            status = "TP"
                        else:
                            expected = expected_by_spl[curr_spl][curr_fusion]
                            if expected is None:  # Fusion is only known by partner and breakpoints are unknown
                                status = "-"
                            else:  # Fusion is known by partner and breakpoints
                                if hasSameCoordinates(expected, first, second):
                                    status = "TP"
                            if status == "FP":
                                rna_types_first = {annot["RNA_ELT_TYPE"] for annot in first.info[annotation_field] if annot["SYMBOL"] == curr_first_gene}
                                rna_types_second = {annot["RNA_ELT_TYPE"] for annot in second.info[annotation_field] if annot["SYMBOL"] == curr_second_gene}
                                for elt in rna_types_first:
                                    if "spliceDonor" in elt or "exonEnd" in elt or "transcriptEnd" in elt:
                                        for elt in rna_types_second:
                                            if "spliceAcceptor" in elt or "exonStart" in elt or "transcriptStart" in elt:
                                                status = "TP_ISOFORM"
                        if status == "TP":
                            selected_fusion = curr_fusion
                # Store fusion
                selected_callers = first.info["SRC"]
                if sofur_filters.eval(first):
                    selected_callers += ["sofur"]
                for curr_src in selected_callers:
                    res_by_fusion = res_by_caller[curr_src][curr_spl]
                    if selected_fusion not in res_by_fusion:
                        res_by_fusion[selected_fusion] = list()
                    res_by_fusion[selected_fusion].append({
                        "genes_1": ";".join(sorted(first_genes)),
                        "genes_2": ";".join(sorted(second_genes)),
                        "status": status,
                        "breakpoint1": "{}:{}".format(first.chrom, first.info["ANNOT_POS"]),
                        "breakpoint2": "{}:{}".format(second.chrom, second.info["ANNOT_POS"]),
                        "support_span": first.samples[curr_spl]["PR"],
                        "support_split": first.samples[curr_spl]["SR"],
                        "filters": ";".join(first.filter),
                        "source": curr_src,
                        "nb_sources": len(first.info["SRC"])
                    })
    return res_by_caller


def writeAggregate(writer, observed_fusions, selected_status, dataset_name, curr_spl):
    """
    Write fusion with higher support from group of same fusion isoforms.

    :param writer: File handle to output file.
    :type writer: anacore.sv.HashedSVIO
    :param observed_fusions: list of observed fusion isoforms.
    :type observed_fusions: list
    :param selected_status: Filter out fusions without these status.
    :type selected_status: set
    :param dataset_name: Name of the dataset.
    :type dataset_name: str
    :param curr_spl: Name of the sample.
    :type curr_spl: str
    """
    selected = [curr for curr in observed_fusions if curr["status"] in selected_status]
    selected = sorted(selected, key=lambda elt: (-elt["support_split"], -elt["support_span"], elt["status"]))
    if len(selected) != 0:
        tmp_best = selected[0].copy()
        tmp_duplcates = []
        for duplicate in selected[1:]:
            tmp_duplcates.append(
                "{}->{}".format(
                    duplicate["breakpoint1"],
                    duplicate["breakpoint2"]
                )
            )
        tmp_best.update({
            "dataset": dataset_name,
            "sample_ID": curr_spl,
            "duplicates": ",".join(tmp_duplcates)
        })
        if tmp_best["status"] == "TP_ISOFORM":
            tmp_best["status"] = "TP"
        writer.write(tmp_best)


def writeResults(output_comparison, res_by_caller, expected_by_spl, dataset_name):
    """
    Write fusions an their status.

    :param output_comparison: path to fusions status file.
    :type output_comparison: str
    :param res_by_caller: By caller the observed fusions and their status (TP, TP_ISOFORM, FP).
    :type res_by_caller: dict
    :param expected_by_spl: By sample a dict of expected fusions: key = gene1<tab>gene2; value = None with unknown breakpoint or dict {"chr1": <v>, "breakpoint1": <v>, "chr2": <v>, "breakpoint2": <v>}.
    :type expected_by_spl: dict
    :param dataset_name: Name of the dataset.
    :type dataset_name: str
    """
    with HashedSVIO(output_comparison, "w") as writer:
        writer.titles = [
            "dataset", "sample_ID", "genes_1", "genes_2", "breakpoint1",
            "breakpoint2", "status", "support_split", "support_span",
            "filters", "source", "duplicates", "nb_sources"
        ]
        for curr_caller, res_by_spl in res_by_caller.items():
            for curr_spl, res_by_partners in res_by_spl.items():
                expected_by_partners = expected_by_spl[curr_spl]
                for curr_partners, observed_fusions in res_by_partners.items():
                    if curr_partners == "unexpected":
                        obs_by_partners = {}
                        for curr_fusion in observed_fusions:
                            real_partners = curr_fusion["genes_1"] + "\t" + curr_fusion["genes_2"]
                            if real_partners not in obs_by_partners:
                                obs_by_partners[real_partners] = []
                            obs_by_partners[real_partners].append(curr_fusion)
                        for real_partners, observed_sub_gp in obs_by_partners.items():
                            for selected_status in [{"TP", "TP_ISOFORM"}, {"-"}, {"FP"}]:
                                writeAggregate(writer, observed_sub_gp, selected_status, dataset_name, curr_spl)
                    else:
                        nb_TP = len([1 for curr_fusion in observed_fusions if curr_fusion["status"] in {"TP", "TP_ISOFORM"}])
                        if curr_partners in expected_by_partners and nb_TP == 0:  # FN
                            writer.write({
                                "dataset": dataset_name,
                                "sample_ID": curr_spl,
                                "genes_1": curr_partners.split("\t")[0],
                                "genes_2": curr_partners.split("\t")[1],
                                "status": "FN",
                                "duplicates": "",
                                "breakpoint1": "NA",
                                "breakpoint2": "NA",
                                "support_span": "NA",
                                "support_split": "NA",
                                "filters": "",
                                "source": curr_caller,
                                "nb_sources": 0
                            })
                        for selected_status in [{"TP", "TP_ISOFORM"}, {"-"}, {"FP"}]:
                            writeAggregate(writer, observed_fusions, selected_status, dataset_name, curr_spl)


################################################################################
#
# MAIN
#
################################################################################
if __name__ == "__main__":
    # Manage parameters
    parser = argparse.ArgumentParser('Compare observed fusions from VCF files to expected fusions from TSV file.')
    parser.add_argument('-m', '--status-mode', choices=["genes", "breakpoints"], default="genes", help='Type of fusion evaluation: only by "genes" partners or by exact "breakpoints". [Default: %(default)s]')
    parser.add_argument('-d', '--dataset-name', required=True, help='Dataset name.')
    parser.add_argument('-f', '--annotation-field', default="ANN", help='Field used to store annotations in VCF. [Default: %(default)s]')
    parser.add_argument('-v', '--version', action='version', version=__version__)
    group_input = parser.add_argument_group('Inputs')  # Inputs
    group_input.add_argument('-i', '--input-filters', required=True, help="Path to file containing filters rules used in sofur (format: JSON).")
    group_input.add_argument('-e', '--input-expected', required=True, help='Path to file containing expected fusions (format: TSV). Columns required: sample_ID, genes_1, genes_2, chr1, breakpoint1, chr2, breakpoint2; For wild-type samples genes_1 = "WT"; For unknown breakpoint breakpoint1 is empty; genes_1 contains symbol for coding genes and gene ID for non-coding.')
    group_input.add_argument('-a', '--inputs-variants', nargs='+', required=True, help="Path to variants files containing observed fusions (format: VCF).")
    group_output = parser.add_argument_group('Outputs')  # Outputs
    group_output.add_argument('-o', '--output-comparison', required=True, help="Path to comparison file (format: TSV).")
    args = parser.parse_args()

    # Logger
    logging.basicConfig(format='%(asctime)s -- [%(filename)s][pid:%(process)d][%(levelname)s] -- %(message)s')
    log = logging.getLogger(os.path.basename(__file__))
    log.setLevel(logging.INFO)
    log.info("Command: " + " ".join(sys.argv))

    # Load expected
    sofur_filters = None
    with open(args.input_filters) as reader:
        sofur_filters = filtersFromDict(json.load(reader))
    expected_by_spl = getExpected(args.input_expected)
    res_by_caller = loadResByCallers(args.inputs_variants, expected_by_spl, sofur_filters, args.status_mode, args.annotation_field)
    writeResults(args.output_comparison, res_by_caller, expected_by_spl, args.dataset_name)
    log.info("End of job")
