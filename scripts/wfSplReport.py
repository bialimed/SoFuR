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
        <!-- D3 -->
        <script type="text/javascript" charset="utf8" src="resources/d3_5.16.0.min.js"></script>
        <!-- DataTables -->
        <link type="text/css" charset="utf8" rel="stylesheet" href="resources/datatables_1.10.18.min.css"/>
        <script type="text/javascript" charset="utf8" src="resources/pdfmake_0.1.36.min.js"></script>
        <script type="text/javascript" charset="utf8" src="resources/vfs_fonts_0.1.36.min.js"></script>
        <script type="text/javascript" charset="utf8" src="resources/datatables_1.10.18.min.js"></script>
        <!-- Bootstrap -->
        <link type="text/css" charset="utf8" rel="stylesheet" href="resources/bootstrap-4.3.1-dist/css/bootstrap.min.css">
        <script type="text/javascript" charset="utf8" src="resources/bootstrap-4.3.1-dist/js/bootstrap.min.js"></script>
        <!-- FontAwesome -->
        <link type="text/css" charset="utf8" rel="stylesheet" href="resources/fontawesome-free-5.13.0-dist/css/all.min.css">
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
                        @see-detail="callDetails"
                        :data=fusions_found
                        :default_source=fusion_ref_source
                        :details_button=true
                        export_title="sample_fusions"
                        title="Fusions found">
                    </fusions-table>
                </div>
            </div>
            <div id="fusion-details" class="card" v-if="selected_fusion !== null">
                <h3 class="card-header">Fusion {{selected_fusion.getSymbolsName()}}</h3>
                <div class="card-block">
                    <fusion-details-table
                        :data=selected_fusion
                        export_title="fusion_detail"
                        title="Transcripts">
                    </fusion-details-table>
                    <div>
                        <div class="viewer-block">
                            <h4>First breakend: {{selected_fusion.getSymbols(0).join(" and ")}}</h4>
                            <breakend-viewer-ac
                                :analysis="breakend_annotations"
                                :breakend="selected_fusion.breakends[0]"
                                order="first"
                                :width="browser_width">
                            </breakend-viewer-ac>
                        </div>
                        <div class="viewer-block">
                            <h4>Second breakend: {{selected_fusion.getSymbols(1).join(" and ")}}</h4>
                            <breakend-viewer-ac
                                :analysis="breakend_annotations"
                                :breakend="selected_fusion.breakends[1]"
                                order="second"
                                :width="browser_width">
                            </breakend-viewer-ac>
                        </div>
                    </div>
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
                    "breakend_annotations": null,
                    "browser_width": null,
                    "fusions_found": null,
                    "fusion_ref_source": "manta",
                    "selected_fusion": null
                },
                mounted: function(){
                    this.loadData()
                    this.browser_width = d3.select(".card-block").node().clientWidth - 60
                },
                methods: {
                    callDetails: function(fusion){
                        this.selected_fusion = fusion
                        this.$nextTick(function () {  // after re-rendering
                            document.querySelector('#fusion-details').scrollIntoView({
                                behavior: 'smooth'
                            })
                        })
                    },
                    loadData: function(){
                        this.fusions_found = ##fusions_data##.map(Fusion.fromJSON)
                        this.breakend_annotations = FusionInspectAnalysis.fromJSON(##inspect_data##)
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
    group_input.add_argument('-f', '--input-fusions', required=True, help='Path to the fusions file (format: JSON).')
    group_input.add_argument('-i', '--input-inspect', required=True, help='Path to the fusions browser data file (format: JSON).')
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
    with open(args.input_inspect) as reader:
        report_content = report_content.replace("##inspect_data##", json.dumps(json.load(reader)))
    with open(args.output_report, "w") as writer:
        writer.write(report_content)
    log.info("End of job.")
