__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'


def standardizeBND(
        in_reference_seq="reference/genome.fasta",
        in_variants="structural_variants/{sample}_unstd.vcf",
        out_variants="structural_variants/{sample}.vcf",
        out_stderr="logs/structural_variants/{sample}_standardize_stderr.txt",
        params_trace_unstandard=None,
        params_keep_outputs=False,
        params_stderr_append=False):
    """Replace N in alt and ref by the convenient nucleotid and move each breakend in pair at the left most position and add uncertainty iin CIPOS tag."""
    rule standardizeBND:
        input:
            genome = in_reference_seq,
            variants = in_variants
        output:
            out_variants if params_keep_outputs else temp(out_variants)
        log:
            out_stderr
        params:
            bin_path = getSoft(config, "standardizeBND.py", "fusion_callers"),
            stderr_redirection = "2>" if not params_stderr_append else "2>>",
            trace_unstandard = "--trace-unstandard" if params_trace_unstandard else "",
        # conda:
        #     "envs/anacore-utils.yml"
        shell:
            "{params.bin_path}"
            " {params.trace_unstandard}"
            " --input-genome {input.genome}"
            " --input-variants {input.variants}"
            " --output-variants {output}"
            " {params.stderr_redirection} {log}"
