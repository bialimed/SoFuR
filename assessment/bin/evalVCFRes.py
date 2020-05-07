#!/usr/bin/env python3

__author__ = 'Veronique Ivashchenko and Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'
__email__ = 'escudie.frederic@iuct-oncopole.fr'
__status__ = 'prod'

import os
import sys
import json
import argparse
import logging
from itertools import product
from anacore.sv import HashedSVIO
from anacore.fusion import BreakendVCFIO


################################################################################
#
# FUNCTIONS
#
################################################################################
def getExpected(input_expected):
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


################################################################################
#
# MAIN
#
################################################################################
if __name__ == "__main__":
    # Manage parameters
    parser = argparse.ArgumentParser('Compare observed fusions from VCF files to expected fusions from TSV file.')
    parser.add_argument('-m', '--status-mode', choices=["genes", "breakpoints"], default="genes", help='Fusion finding by genes or by breakpoints. [Default: %(default)s]')
    parser.add_argument('-d', '--dataset-name', required=True, help='Dataset name.')
    parser.add_argument('-f', '--annotation-field', default="ANN", help='Field used for store annotations. [Default: %(default)s]')
    parser.add_argument('-v', '--version', action='version', version=__version__)
    group_input = parser.add_argument_group('Inputs')  # Inputs
    group_input.add_argument('-e', '--input-expected', required=True, help="Path to file containing expected fusions (format: TSV).")
    group_input.add_argument('-a', '--inputs-variants', nargs='+', required=True, help="Path to variants files containing observed fusions (format: VCF).")
    group_output = parser.add_argument_group('Outputs')  # Outputs
    group_output.add_argument('-o', '--output-comparison', required=True, help="Path to comparison file (format: TSV).")
    args = parser.parse_args()

    # Logger
    logging.basicConfig(format='%(asctime)s -- [%(filename)s][pid:%(process)d][%(levelname)s] -- %(message)s')
    log = logging.getLogger(os.path.basename(__file__))
    log.setLevel(logging.INFO)
    log.info("Command: " + " ".join(sys.argv))

    # Process
    with HashedSVIO(args.output_comparison, "w") as writer:
        writer.titles = [
            "dataset", "sample_ID", "genes_1", "genes_2", "breakpoint1",
            "breakpoint2", "status", "support_split", "support_span", "filters",
            "source", "nb_sources"
        ]
        # Load expected
        expected_by_spl = getExpected(args.input_expected)
        # Process comparison
        for curr_vcf in args.inputs_variants:
            with BreakendVCFIO(curr_vcf, "r", annot_field=args.annotation_field) as reader:
                curr_spl = reader.samples[0]
                callers_id_desc = reader.info["SRC"].description.split("Possible values: ")[1].replace("'", '"')
                callers = json.loads(callers_id_desc).keys()
                # True positives and False negatives
                tp_by_callers = {curr_caller: set() for curr_caller in callers}
                na_by_callers = {curr_caller: set() for curr_caller in callers}
                for first, second in reader:
                    status = "FP"
                    first_genes = {annot["SYMBOL"] for annot in first.info[args.annotation_field]}
                    second_genes = {annot["SYMBOL"] for annot in second.info[args.annotation_field]}
                    for curr_first_gene, curr_second_gene in product(first_genes, second_genes):
                        curr_fusion = curr_first_gene + "\t" + curr_second_gene
                        if curr_fusion in expected_by_spl[curr_spl]:
                            if args.status_mode == "genes":
                                status = "TP"
                            else:
                                expected = expected_by_spl[curr_spl][curr_fusion]
                                if expected is None:  # Fusion is only known by partner and breakpoints are unknown
                                    status = "NA"
                                    for curr_src in first.info["SRC"]:
                                        na_by_callers[curr_src].add(curr_fusion)
                                else:  # Fusion is known by partner and breakpoints
                                    if first.info["ANNOT_POS"] == expected["pos1"] and second.info["ANNOT_POS"] == expected["pos2"]:
                                        status = "TP"
                                    else:
                                        if "CIPOS" in first.info and "CIPOS" in second.info:
                                            first_bnd_limit_left = first.pos - abs(first.info["CIPOS"][0])
                                            first_bnd_limit_right = first.pos + first.info["CIPOS"][1]
                                            second_bnd_limit_left = second.pos - abs(second.info["CIPOS"][0])
                                            second_bnd_limit_right = second.pos + second.info["CIPOS"][1]
                                            if expected["pos1"] >= first_bnd_limit_left and expected["pos1"] <= first_bnd_limit_right:
                                                if expected["pos2"] >= second_bnd_limit_left and expected["pos2"] <= second_bnd_limit_right:
                                                    status = "TP"
                            if status == "TP":
                                for curr_src in first.info["SRC"]:
                                    tp_by_callers[curr_src].add(curr_fusion)
                    for curr_src in first.info["SRC"]:
                        writer.write({
                            "dataset": args.dataset_name,
                            "sample_ID": curr_spl,
                            "genes_1": ";".join(first_genes),
                            "genes_2": ";".join(second_genes),
                            "status": status,
                            "breakpoint1": "{}:{}".format(first.chrom, first.info["ANNOT_POS"]),
                            "breakpoint2": "{}:{}".format(second.chrom, second.info["ANNOT_POS"]),
                            "support_span": first.samples[curr_spl]["PR"],
                            "support_split": first.samples[curr_spl]["SR"],
                            "filters": ";".join(first.filter),
                            "source": curr_src,
                            "nb_sources": len(first.info["SRC"])
                        })
                # False negatives
                expected_set = set(expected_by_spl[curr_spl].keys()) ######################### pb when several fusions with same partners
                for caller, true_positives_set in tp_by_callers.items():
                    false_negative_set = expected_set - true_positives_set
                    false_negative_set = false_negative_set - na_by_callers[caller]
                    for curr_fusion in sorted(false_negative_set):
                        expected = expected_by_spl[curr_spl][curr_fusion]
                        writer.write({
                            "dataset": args.dataset_name,
                            "sample_ID": curr_spl,
                            "genes_1": curr_fusion.split("\t")[0],
                            "genes_2": curr_fusion.split("\t")[1],
                            "status": "FN",
                            "breakpoint1": "NA",
                            "breakpoint2": "NA",
                            "support_span": "NA",
                            "support_split": "NA",
                            "filters": "NA",
                            "source": caller,
                            "nb_sources": 0
                        })
