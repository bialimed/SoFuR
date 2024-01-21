__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 CHU Toulouse'
__license__ = 'GNU General Public License'
__version__ = '1.2.0'


def wfReport(
        params_samples,
        in_fusions="report/data/{sample}_fusions_filtered.json",
        in_inspects="report/data/{sample}_fusions_inspect.json",
        in_interop_summary=None,
        in_resources_folder=None,
        in_run_summary=None,
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
        in_resources_folder = os.path.join(workflow.basedir, "report_resources")
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
        resources:
            extra = "",
            mem = "1G",
            partition = "normal"
        shell:
            "mkdir -p {params.report_dir} && cp -r {input} {output}"
            " 2> {log}"
    # Create sample report
    rule wfSplReport:
        input:
            lib = out_resources_folder,  # Not input but necessary to output
            fusions = in_fusions,
            inspect = in_inspects
        output:
            out_spl_reports
        log:
            out_stderr_spl
        params:
            bin_path = os.path.abspath(os.path.join(workflow.basedir, "scripts/wfSplReport.py")),
            sample = "--sample-name {" + params_sample_wildcard + "}" if params_sample_wildcard != "" else ""
        resources:
            extra = "",
            mem = "2G",
            partition = "normal"
        shell:
            "{params.bin_path}"
            " {params.sample}"
            " --input-fusions {input.fusions}"
            " --input-inspect {input.inspect}"
            " --output-report {output}"
            " 2> {log}"
    # Create run report
    with open(out_sample_list, "w") as handle:  # Creates list of samples
        for curr_spl in params_samples:
            handle.write(curr_spl + "\n")
    rule wfRunReport:
        input:
            lib = out_resources_folder,  # Not input but necessary to output
            interop_summary = ([] if in_interop_summary is None else in_interop_summary),
            run_summary = ([] if in_run_summary is None else in_run_summary),
            samples = out_sample_list
        output:
            out_run_report
        log:
            out_stderr_run
        params:
            bin_path = os.path.abspath(os.path.join(workflow.basedir, "scripts/wfRunReport.py")),
            interop_summary = "" if in_interop_summary is None else "--input-interop " + in_interop_summary,
            run_summary = "" if in_run_summary is None else "--input-run " + in_run_summary
        resources:
            extra = "",
            mem = "1G",
            partition = "normal"
        shell:
            "{params.bin_path}"
            " --input-samples {input.samples}"
            " {params.interop_summary}"
            " {params.run_summary}"
            " --output-report {output}"
            " 2> {log}"
