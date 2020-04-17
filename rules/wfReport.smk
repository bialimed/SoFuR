__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'


def wfReport(
        params_samples,
        in_fusions="report/data/{sample}_fusions_filtered.json",
        in_resources_folder=None,
        out_run_report="report/run.html",
        out_sample_list="sample_list.txt",
        out_spl_reports="report/{sample}.html",
        out_stderr_cpRsc="logs/report/cpReportResources_stderr.txt",
        out_stderr_run="logs/report/run_stderr.txt",
        out_stderr_spl="logs/report/{sample}_stderr.txt",
        params_sample_wildcard="sample"):  # Use "" instead to inactivate
    """Write samples and run reports."""
    # Copy web resources
    if in_resources_folder is None:
        app_folder = os.path.dirname(workflow.snakefile)
        in_resources_folder = os.path.join(app_folder, "report_resources")
    out_report_folder = os.path.dirname(out_spl_reports)
    out_resources_folder = os.path.join(out_report_folder, "resources")
    rule cpReportResources:
        input:
            in_resources_folder
        output:
            directory(out_resources_folder)
        log:
            out_stderr_cpRsc
        params:
            report_dir = out_report_folder
        shell:
            "mkdir -p {params.report_dir} && cp -r {input} {output}"
            " 2> {log}"
    # Create sample report
    rule wfSplReport:
        input:
            lib = out_resources_folder,  # Not input but necessary to output
            fusions = in_fusions,
        output:
            out_spl_reports
        log:
            out_stderr_spl
        params:
            bin_path = os.path.abspath(os.path.join(os.path.dirname(workflow.snakefile), "scripts/wfSplReport.py")),
            sample = "--sample-name {" + params_sample_wildcard + "}" if params_sample_wildcard != "" else ""
        shell:
            "{params.bin_path}"
            " {params.sample}"
            " --input-fusions {input.fusions}"
            " --output-report {output}"
            " 2> {log}"
    # Create run report
    with open(out_sample_list, "w") as handle:  # Creates list of samples
        for curr_spl in params_samples:
            handle.write(curr_spl + "\n")
    rule wfRunReport:
        input:
            lib = out_resources_folder,  # Not input but necessary to output
            samples = out_sample_list
        output:
            out_run_report
        log:
            out_stderr_run
        params:
            bin_path = os.path.abspath(os.path.join(os.path.dirname(workflow.snakefile), "scripts/wfRunReport.py")),
        shell:
            "{params.bin_path}"
            " --input-samples {input.samples}"
            " --output-report {output}"
            " 2> {log}"
