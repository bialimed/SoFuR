#!/usr/bin/env python

__author__ = 'Veronique Ivashchenko and Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'
__email__ = 'escudie.frederic@iuct-oncopole.fr'
__status__ = 'prod'

import os
import sys
import gzip
import argparse
import logging


########################################################################
#
# MAIN
#
########################################################################
if __name__ == "__main__":
    # Manage parameters
    parser = argparse.ArgumentParser('Fix header tags in VCF coming from Manta.')
    parser.add_argument('-v', '--version', action='version', version=__version__)
    parser.add_argument('-i', '--input-variants', required=True, help="Path to manta VCF file.")
    parser.add_argument('-o', '--output-variants', required=True, help="Path to fixed output.")
    args = parser.parse_args()

    # Logger
    logging.basicConfig(format='%(asctime)s -- [%(filename)s][pid:%(process)d][%(levelname)s] -- %(message)s')
    log = logging.getLogger(os.path.basename(__file__))
    log.setLevel(logging.INFO)
    log.info("Command: " + " ".join(sys.argv))

    # Process
    handler = gzip.open if args.output_variants.endswith(".gz") else open
    mode = "wt" if args.output_variants.endswith(".gz") else "w"
    with handler(args.output_variants, mode) as writer:
        with gzip.open(args.input_variants, "rt") as reader:
            for line in reader:
                if line.startswith("##FORMAT"):
                    if "ID=SR," in line or "ID=PR," in line:
                        line = line.replace("Number=.", "Number=R")
                writer.write(line)

    # Log process
    log.info("End of job")
