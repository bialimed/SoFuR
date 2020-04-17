#!/usr/bin/env python3

__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'
__email__ = 'escudie.frederic@iuct-oncopole.fr'
__status__ = 'prod'

import os
import sys
import json
import logging
import argparse


########################################################################
#
# FUNCTIONS
#
########################################################################
def getTemplate():
    return """<html>
    <head>
        <title>Run</title>
        <meta charset="UTF-8">
        <meta name="author" content="Escudie Frederic">
        <meta name="version" content="1.0.0">
        <meta name="copyright" content="2020 IUCT-O">
        <!-- Bootstrap -->
        <link type="text/css" charset="utf8" rel="stylesheet" href="resources/bootstrap-4.3.1-dist/css/bootstrap.min.css">
        <script type="text/javascript" charset="utf8" src="resources/bootstrap-4.3.1-dist/js/bootstrap.min.js"></script>
        <!-- WebComponents -->
        <link type="text/css" charset="utf8" rel="stylesheet" href="resources/webCmpt.min.css"></script>
        <script type="text/javascript" charset="utf8" src="resources/vue_2.6.10.min.js"></script>
    </head>
    <body>
        <nav class="navbar fixed-top justify-content-center">
            <span class="align-middle">Run</span>
        </nav>
        <div class="page-content">
            <div class="card">
                <h3 class="card-header">Samples</h3>
                <div class="card-block">
                    <ul class="list-group">
                        <div class="row" v-for="curr_spl in samples">
                            <div class="col-sm-0 col-md-2"></div>
                            <a :href="splToUrl(curr_spl)" class="list-group-item app-spl-link col-sm-12 col-md-8">
                                {{curr_spl}}
                            </a>
                            <div class="col-sm-0 col-md-2"></div>
                        </div>
                    </ul>
                </div>
            </div>
        </div>
        <script>
            new Vue({
                el: ".page-content",
                data: {
                    "samples": ##samples##,
                },
                methods: {
                    splToUrl: function(spl){
                        return spl + ".html"
                    }
                }
            })
        </script>
    </body>
</html>"""


########################################################################
#
# MAIN
#
########################################################################
if __name__ == "__main__":
    # Manage parameters
    parser = argparse.ArgumentParser(description="Create strada's HTML report for run.")
    parser.add_argument('-v', '--version', action='version', version=__version__)
    group_input = parser.add_argument_group('Inputs')
    group_input.add_argument('-s', '--input-samples', required=True, help='Path to list of samples name (format: txt).')
    group_output = parser.add_argument_group('Outputs')
    group_output.add_argument('-o', '--output-report', help='Path to the outputted report file (format: HTML).')
    args = parser.parse_args()

    # Logger
    logging.basicConfig(format='%(asctime)s - %(name)s [%(levelname)s] %(message)s')
    log = logging.getLogger(os.path.basename(__file__))
    log.setLevel(logging.INFO)
    log.info("Command: " + " ".join(sys.argv))

    # Process
    report_content = getTemplate()
    with open(args.input_samples) as reader:
        samples = sorted([elt.strip() for elt in reader.readlines()])
        report_content = report_content.replace("##samples##", json.dumps(samples))
    with open(args.output_report, "w") as writer:
        writer.write(report_content)
    log.info("End of job.")
