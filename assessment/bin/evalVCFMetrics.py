#!/usr/bin/env python3

__author__ = 'Veronique Ivashchenko and Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 CHU Toulouse'
__license__ = 'GNU General Public License'
__version__ = '1.1.0'

import os
import sys
import argparse
import logging
from anacore.sv import HashedSVIO


########################################################################
#
# MAIN
#
########################################################################
if __name__ == "__main__":
    # Manage parameters
    parser = argparse.ArgumentParser('Extract performance metrics in TSV file from evalVCFRes.py output.')
    parser.add_argument('-f', '--annotation-field', default="ANN", help='Field used for store annotations. [Default: %(default)s]')
    parser.add_argument('-v', '--version', action='version', version=__version__)
    group_input = parser.add_argument_group('Inputs')  # Inputs
    group_input.add_argument('-i', '--input-variants', required=True, help="Path to output file from evalVCFRes.py (format: TSV).")
    group_output = parser.add_argument_group('Outputs')  # Outputs
    group_output.add_argument('-o', '--output-metrics', required=True, help="Path to performance metrics file (format: TSV).")
    args = parser.parse_args()

    # Logger
    logging.basicConfig(format='%(asctime)s -- [%(filename)s][pid:%(process)d][%(levelname)s] -- %(message)s')
    log = logging.getLogger(os.path.basename(__file__))
    log.setLevel(logging.INFO)
    log.info("Command: " + " ".join(sys.argv))

    # Get counts
    results_by_dataset = {}
    with HashedSVIO(args.input_variants, "r") as reader:
        for record in reader:
            dataset = record["dataset"]
            if dataset not in results_by_dataset:
                results_by_dataset[dataset] = {}
            src = record["source"]
            if src not in results_by_dataset[dataset]:
                results_by_dataset[dataset][src] = {"TP": 0, "FP": 0, "FN": 0, "-": 0}
            results_by_dataset[dataset][src][record["status"]] += 1

    # Write results
    with HashedSVIO(args.output_metrics, "w") as writer:
        writer.titles = ["dataset", "source", "TP", "FP", "FN", "NA", "precision", "recall"]
        for dataset, res_by_src in results_by_dataset.items():
            for src, res in res_by_src.items():
                writer.write({
                    "dataset": dataset,
                    "source": src,
                    "TP": res["TP"],
                    "FP": res["FP"],
                    "FN": res["FN"],
                    "NA": res["-"],
                    "precision": "{:.4f}".format(res["TP"] / (res["TP"] + res["FP"])),
                    "recall": "{:.4f}".format(res["TP"] / (res["TP"] + res["FN"]))
                })
    log.info("End of job")
