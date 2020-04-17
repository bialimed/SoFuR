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
        <title>Fusions analysis</title>
        <meta charset="UTF-8">
        <meta name="author" content="Escudie Frederic">
        <meta name="version" content="1.0.0">
        <meta name="copyright" content="2020 IUCT-O">
        <!-- jQuery -->
        <script type="text/javascript" charset="utf8" src="resources/jquery_3.3.1.min.js"></script>
        <!-- HighCharts -->
        <script type="text/javascript" charset="utf8" src="resources/highcharts_7.1.0.min.js"></script>
        <script type="text/javascript" charset="utf8" src="resources/highcharts-more_7.1.0.min.js"></script>
        <!-- DataTables -->
        <link type="text/css" charset="utf8" rel="stylesheet" href="resources/datatables_1.10.18.min.css"/>
        <script type="text/javascript" charset="utf8" src="resources/pdfmake_0.1.36.min.js"></script>
        <script type="text/javascript" charset="utf8" src="resources/vfs_fonts_0.1.36.min.js"></script>
        <script type="text/javascript" charset="utf8" src="resources/datatables_1.10.18.min.js"></script>
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
            <span class="align-middle">
                <template v-if="sample_name === null">Fusions analysis</template>
                <template v-else>Sample {{sample_name}}</template>
            </span>
        </nav>
        <div class="page-content">
            <div class="card">
                <h3 class="card-header">Fusions</h3>
                <div class="card-block">
                    <fusions-table
                        :data=fusions_found
                        :default_source=fusion_ref_source
                        export_title="sample_fusions"
                        title="Fusions found">
                    </fusions-table>
                </div>
            </div>
            <div class="card">
                <h3 class="card-header">Fusion detail</h3>
                <div class="card-block">
                    Select fusion in table above
                </div>
            </div>
        </div>
        <script>
            // Navbar
            new Vue({
                el: "nav.fixed-top",
                data: {
                    "sample_name": ##sample_name##
                }
            })
            // Page content
            new Vue({
                el: ".page-content",
                data: {
                    "fusions_found": null,
                    "fusion_ref_source": "manta"
                },
                mounted: function(){
                    this.loadData()
                },
                methods: {
                    loadData: function(){
                        this.fusions_found = ##fusions_data##.map(Fusion.fromJSON)
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
    parser = argparse.ArgumentParser(description="Create strada's HTML report for one sample.")
    parser.add_argument('-n', '--sample-name', help='The sample name.')
    parser.add_argument('-v', '--version', action='version', version=__version__)
    group_input = parser.add_argument_group('Inputs')
    group_input.add_argument('-i', '--input-fusions', required=True, help='Path to the fusions file (format: JSON).')
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
    report_content = report_content.replace("##sample_name##", json.dumps(args.sample_name))
    with open(args.input_fusions) as reader:
        report_content = report_content.replace("##fusions_data##", json.dumps(json.load(reader)))
    with open(args.output_report, "w") as writer:
        writer.write(report_content)
    log.info("End of job.")
