#!/usr/bin/env python3

__author__ = 'Veronique Ivashchenko and Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'
__email__ = 'escudie.frederic@iuct-oncopole.fr'
__status__ = 'prod'

import os
import sys
import argparse
import logging
from itertools import product
from anacore.sv import HashedSVIO
from anacore.fusion import BreakendVCFIO

########################################################################
#
# MAIN
#
########################################################################
if __name__ == "__main__":
    # Manage parameters
    parser = argparse.ArgumentParser('Compare observed fusions from VCF files to expected fusions from TSV file.')
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
        writer.titles = ["sample_ID", "genes_1", "genes_2", "status", "support_split", "support_span", "filters", "sources"]
        expected_by_spl = dict()
        with HashedSVIO(args.input_expected, "r") as reader:
            for record in reader:
                spl = record["sample_ID"]
                fusion = record["gene1"] + "\t" + record["gene2"]
                if spl not in expected_by_spl:
                    expected_by_spl[spl] = set()
                expected_by_spl[spl].add(fusion)
        for curr_vcf in args.inputs_variants:
            with BreakendVCFIO(curr_vcf, "r", annot_field=args.annotation_field) as reader:
                curr_spl = reader.samples[0]
                # True positives and False negatives
                true_positives_set = set()
                for first, second in reader:
                    first_genes = {annot["SYMBOL"] for annot in first.info[args.annotation_field]}
                    second_genes = {annot["SYMBOL"] for annot in second.info[args.annotation_field]}
                    status = "FP"
                    for curr_first_gene, curr_second_gene in product(first_genes, second_genes):
                        curr_fusion = curr_first_gene + "\t" + curr_second_gene
                        if curr_fusion in expected_by_spl[curr_spl]:
                            true_positives_set.add(curr_fusion)
                            status = "TP"
                    writer.write({
                        "sample_ID": curr_spl,
                        "genes_1": ";".join(sorted(first_genes)),
                        "genes_2": ";".join(sorted(second_genes)),
                        "status": status,
                        "support_span": first.samples[curr_spl]["PR"],
                        "support_split": first.samples[curr_spl]["SR"],
                        "filters": ";".join(first.filter),
                        "sources": ";".join(first.info["SRC"])
                    })
                # False negatives
                false_negatives = expected_by_spl[curr_spl] - true_positives_set
                for curr_fusion in sorted(false_negatives):
                    writer.write({
                        "sample_ID": curr_spl,
                        "genes_1": curr_fusion.split("\t")[0],
                        "genes_2": curr_fusion.split("\t")[1],
                        "status": "FN",
                        "support_span": "NA",
                        "support_split": "NA",
                        "filters": "NA",
                        "sources": "NA"
                    })
