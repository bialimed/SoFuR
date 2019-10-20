__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2019 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'


rule_name = "manta_kwargs"
_rule_kwargs[rule_name] = {
    # Inputs
    "in.alignments": getRuleParam(locals(), rule_name, "in.alignments", "aln/markDup/{sample}.bam"),
    "in.reference_seq": getRuleParam(locals(), rule_name, "in.reference_seq", "data/reference.fa"),
    # Outputs
    "out.small_indel": getRuleParam(locals(), rule_name, "out.small_indel", "structural_variants/manta/{sample}_smallInDel.vcf.gz"),
    "out.sv_candidate": getRuleParam(locals(), rule_name, "out.sv_candidate", "structural_variants/manta/{sample}_SVCandidates.vcf.gz"),
    "out.sv": getRuleParam(locals(), rule_name, "out.sv", "structural_variants/manta/{sample}_SV.vcf.gz"),
    "out.stderr_cfg": getRuleParam(locals(), rule_name, "out.stderr", "logs/structural_variants/{sample}_mantaConfig_stderr.txt"),
    "out.stderr_run": getRuleParam(locals(), rule_name, "out.stderr", "logs/structural_variants/{sample}_mantaRun_stderr.txt"),
    # Parameters
    "params.is_somatic": getRuleParam(locals(), rule_name, "params.is_somatic", True),
    "params.keep_outputs": getRuleParam(locals(), rule_name, "params.keep_outputs", False),
    "params.mem_gb": getRuleParam(locals(), rule_name, "params.mem_gb", 20),
    "params.min_candidate_spanning" = getRuleParam(locals(), rule_name, "params.min_candidate_spanning", 3),  # Manta is configured with a discovery sensitivity appropriate for general WGS applications. In targeted or other specialized contexts the candidate sensitivity can be increased. A recommended general high sensitivity mode can be obtained by changing the two values 'minEdgeObservations' and 'minCandidateSpanningCount' in the manta configuration file (see 'Advanced configuration options' above) to 2 observations per candidate (the default is 3)
    "params.min_edge_obs" = getRuleParam(locals(), rule_name, "params.min_edge_obs", 3),  # Manta is configured with a discovery sensitivity appropriate for general WGS applications. In targeted or other specialized contexts the candidate sensitivity can be increased. A recommended general high sensitivity mode can be obtained by changing the two values 'minEdgeObservations' and 'minCandidateSpanningCount' in the manta configuration file (see 'Advanced configuration options' above) to 2 observations per candidate (the default is 3)
    "params.type": getRuleParam(locals(), rule_name, "params.type", "rna")  # rna or targeted or genome
}
# Manage the parameter type
opt_by_type = {"rna": "--rna", "targeted": "--exome", "genome": ""}
if _rule_kwargs[rule_name]["params.type"] not in opt_by_type:
    raise Exception('The parameter "type" must be in: {}'.format(sorted(list(opt_by_type.keys()))))
_rule_kwargs[rule_name]["out.run_dir"] = _rule_kwargs[rule_name]["out.structural_variants"] + "/work_{sample}",


################ check outputs filenames with rna + isSomatic, rna - isSomatic, exome + isSomatic, exome - isSomatic, genome - isSomatic, genome + isSomatic

# Configurate manta
rule mantaConfig:
    input:
        alignments = _rule_kwargs[rule_name]["in.alignments"],
        reference_seq = _rule_kwargs[rule_name]["in.reference_seq"]
    output:
        temp(directory(_rule_kwargs[rule_name]["out.run_dir"]))
    log:
        stderr = _rule_kwargs[rule_name]["out.stderr_cfg"]
    params:
        bin_path = getSoft(config, "configManta.py", "manta_rule"),
        bam = "tumorBam" if _rule_kwargs[rule_name]["params.is_somatic"] and _rule_kwargs[rule_name]["params.type"] != "rna" else "bam"  # When RNA mode is turned on, exactly one sample must be specified as normal input only (using either the --bam or --normalBam option)
        min_candidate_spanning = _rule_kwargs[rule_name]["params.min_candidate_spanning"]
        min_edge_obs = _rule_kwargs[rule_name]["params.min_edge_obs"]
        type = opt_by_type[_rule_kwargs[rule_name]["params.type"]],
    shell:
        " cp `which`.ini {output.run_dir} 2> {log.stderr}"
        " && "
        "sed -i -E "s/^minEdgeObservations = [[:digit:]]+/minEdgeObservations = {params.min_edge_obs}/g" {output.run_dir}/runWorkflow.py.ini 2>> {log.stderr}"
        " && "
        "sed -i -E "s/^minCandidateSpanningCount = [[:digit:]]+/minCandidateSpanningCount = {params.min_candidate_spanning}/g" {output.run_dir}/runWorkflow.py.ini 2>> {log.stderr}"
        " && "
        "{params.bin_path}"
        " {params.type}"
        " --config {input.config}"
        " --referenceFasta {input.reference_seq}"
        " --{params.bam} {input.alignments}"
        " --runDir {output.run_dir}"
        " 2>> {log.stderr}"


# Run manta
rule mantaRun:
    input:
        _rule_kwargs[rule_name]["out.run_dir"]
    output:
        small_indel = temp(_rule_kwargs[rule_name]["out.small_indel"] if _rule_kwargs[rule_name]["params.keep_outputs"] else temp(_rule_kwargs[rule_name]["out.small_indel"]),
        sv_candidate = temp(_rule_kwargs[rule_name]["out.sv_candidate"] if _rule_kwargs[rule_name]["params.keep_outputs"] else temp(_rule_kwargs[rule_name]["out.sv_candidate"]),
        sv = temp(_rule_kwargs[rule_name]["out.sv"] if _rule_kwargs[rule_name]["params.keep_outputs"] else temp(_rule_kwargs[rule_name]["out.sv"])
    log:
        stderr = _rule_kwargs[rule_name]["out.stderr_run"]
    params:
        mem_gb = _rule_kwargs[rule_name]["params.mem_gb"],
        sv_filename = "rnaSV.vcf.gz" if _rule_kwargs[rule_name]["out.type"] == "rna" else ("tumorSV.vcf.gz" if _rule_kwargs[rule_name]["params.is_somatic"] else "somaticSV.vcf.gz")
    shell:
        "{input}/runWorkflow.py"
        " --mode local"
        " --memGb {params.mem_gb}"
        " --runDir {input}"
        " 2> {log.stderr}"
        " && "
        "mv {input}/results/variants/candidateSmallIndels.vcf.gz {output.small_indel} 2>> {log.stderr}"
        " && "
        "mv {input}/results/variants/candidateSV.vcf.gz {output.sv_candidate} 2>> {log.stderr}"
        " && "
        "mv {input}/results/variants/{params.sv_filename} {output.sv} 2>> {log.stderr}"


del(_rule_kwargs[rule_name])
