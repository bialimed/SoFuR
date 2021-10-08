#!/usr/bin/env python3

__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.1.0'
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
        <meta name="version" content="1.1.0">
        <meta name="copyright" content="2020 IUCT-O">
        <!-- jQuery -->
        <script type="text/javascript" charset="utf8" src="resources/jquery_3.3.1.min.js"></script>
        <!-- HighCharts -->
        <script type="text/javascript" charset="utf8" src="resources/highcharts_7.1.0.min.js"></script>
        <script type="text/javascript" charset="utf8" src="resources/highcharts-more_7.1.0.min.js"></script>
        <!-- Bootstrap -->
        <link type="text/css" charset="utf8" rel="stylesheet" href="resources/bootstrap-4.3.1-dist/css/bootstrap.min.css">
        <script type="text/javascript" charset="utf8" src="resources/bootstrap-4.3.1-dist/js/bootstrap.min.js"></script>
        <!-- WebComponents -->
        <link type="text/css" charset="utf8" rel="stylesheet" href="resources/webCmpt.min.css"></script>
        <script type="text/javascript" charset="utf8" src="resources/vue_2.6.10.min.js"></script>
        <script type="text/javascript" charset="utf8" src="resources/webCmpt.min.js"></script>
    </head>
    <body>
        <nav class="navbar fixed-top justify-content-center">
            <span class="align-middle">Run</span>
        </nav>
        <div class="page-content">
            <div class="card" v-if="interop_summary !== null">
                <h3 class="card-header">Run density</h3>
                <div class="card-block">
                    <run-density-card-content v-if="interop_summary !== null"
                        :run_info=run_info
                        :interop_summary=interop_summary>
                    </run-density-card-content>
                </div>
            </div>
            <div class="card" v-if="run_info !== null">
                <h3 class="card-header">Error rate</h3>
                <div class="card-block">
                    <run-quality-card-content v-if="interop_summary !== null"
                        :run_phases=run_info.reads_phases
                        :interop_summary=interop_summary>
                    </run-quality-card-content>
                </div>
            </div>
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
                    "interop_summary": null,
                    "samples": ##samples##,
                    "run_info": null
                },
                mounted: function(){
                    this.loadData()
                },
                methods: {
                    loadData: function(){
                        this.run_info = ##run_data##
                        this.interop_summary = ##interop_data##
                    },
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
    parser = argparse.ArgumentParser(description="Create sofur's HTML report for run.")
    parser.add_argument('-v', '--version', action='version', version=__version__)
    group_input = parser.add_argument_group('Inputs')
    group_input.add_argument('-i', '--input-interop', help='Path to interop summary (format: JSON).')
    group_input.add_argument('-r', '--input-run', help='Path to run advanced info (format: JSON).')
    group_input.add_argument('-s', '--input-samples', required=True, help='Path to list of samples name (format: txt).')
    group_output = parser.add_argument_group('Outputs')
    group_output.add_argument('-o', '--output-report', help='Path to the outputted report file (format: HTML).')
    args = parser.parse_args()

    # Logger
    logging.basicConfig(format='%(asctime)s - %(name)s [%(levelname)s] %(message)s')
    log = logging.getLogger(os.path.basename(__file__))
    log.setLevel(logging.INFO)
    log.info("Command: " + " ".join(sys.argv))

    # Get template
    report_content = getTemplate()

    # Set samples link
    with open(args.input_samples) as reader:
        samples = sorted([elt.strip() for elt in reader.readlines()])
        report_content = report_content.replace("##samples##", json.dumps(samples))

    # Set interop
    interop_data = "null"
    if args.input_interop is not None:
        with open(args.input_interop) as reader_interop:
            interop_data = json.dumps(json.load(reader_interop))
    report_content = report_content.replace("##interop_data##", interop_data)

    # Set run
    run_data = "null"
    if args.input_run is not None:
        with open(args.input_run) as reader_run:
            run_data = json.dumps(json.load(reader_run))
    report_content = report_content.replace("##run_data##", run_data)

    # Write output
    with open(args.output_report, "w") as writer:
        writer.write(report_content)
    log.info("End of job.")
