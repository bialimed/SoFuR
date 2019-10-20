__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2019 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'


rule_name = "AnnotBND_kwargs"
_rule_kwargs[rule_name] = {
    # Inputs
    "in.fusion_data": getRuleParam(locals(), rule_name, "in.fusion_data"),  # Required
    "in.R1": getRuleParam(locals(), rule_name, "in.R1"),  # Required
    "in.R2": getRuleParam(locals(), rule_name, "in.R2", None),
    # Outputs
    "out.stdout": getRuleParam(locals(), rule_name, "out.stdout", "logs/structural_variants/{sample}_{variant_caller}_stdout.txt"),
    "out.stderr": getRuleParam(locals(), rule_name, "out.stderr", "logs/structural_variants/{sample}_{variant_caller}_stderr.txt"),
    "out.summary": getRuleParam(locals(), rule_name, "out.summary", "structural_variants/fusionCatcher/{sample}_summary.tsv"),
    "out.variants": getRuleParam(locals(), rule_name, "out.variants", "structural_variants/fusionCatcher/{sample}_SV.vcf.gz"),
    "out.variants_txt": getRuleParam(locals(), rule_name, "out.variants_txt", "structural_variants/fusionCatcher/{sample}_SV.txt"),
    # Parameters
    "params.keep_outputs": getRuleParam(locals(), rule_name, "params.keep_outputs", False),
    "params.nb_threads": getRuleParam(locals(), rule_name, "params.nb_threads", 10),
    "params.sort_buffer_size": getRuleParam(locals(), rule_name, "params.sort_buffer_size", 30),
}
_rule_kwargs[rule_name]["out.folder"] = "`basename " + _rule_kwargs[rule_name]["out.variants"] + "`/{sample}"


rule fusionCatcher:
    input:
        fusion_data = _rule_kwargs[rule_name]["in.fusion_data"],
        R1 = _rule_kwargs[rule_name]["in.R1"],
        R2 = _rule_kwargs[rule_name]["in.R2"]
    output:
        folder = tmp(directory(_rule_kwargs[rule_name]["out.folder"]))
        variants_txt = _rule_kwargs[rule_name]["out.variants_txt"] if _rule_kwargs[rule_name]["params.keep_outputs"] else tmp(_rule_kwargs[rule_name]["out.variants_txt"]),
        summary = _rule_kwargs[rule_name]["out.summary"],
        log:
            stderr = _rule_kwargs[rule_name]["out.stderr"],
            stdout = _rule_kwargs[rule_name]["out.stdout"]
    params:
        bin_path = getSoft(config, "fusioncatcher", "fusionCatcher_rule"),
        single_end = "--single-end" if _rule_kwargs[rule_name]["in.R2"] is None else "",
        sort_buffer_size = _rule_kwargs[rule_name]["params.sort_buffer_size"]
    conda:
        "../envs/fusionCatcher.yml"
    threads: _rule_kwargs[rule_name]["params.nb_threads"],
    shell:
        "mkdir -p {output.folder}/raw 2> {log.stderr}"
        " && "
        "cp {in.R1} {in.R2} {output.folder}/raw 2>> {log.stderr}"
        " && "
        "{params.bin_path}"
        " --skip-update-check"
        " --threads {threads}"
        " --sort-buffer-size {params.sort_buffer_size}"
        " {params.single_end}"
        " --data {input.fusion_data}"
        " --input {output.folder}/raw"
        " --output {output.folder}"
        " 2>> {log.stderr}"
        " && "
        " mv {output.raw_folder}/fusioncatcher.log {log.stdout} 2>> {log.stderr}"
        " && "
        " mv {output.raw_folder}/summary_candidate_fusions.txt {output.summary} 2>> {log.stderr}"
        " && "
        " mv {output.raw_folder}/final-list_candidate_fusion_genes.txt {output.variants_txt} 2>> {log.stderr}"


rule fusionCatcherToVCF:
    input:
        _rule_kwargs[rule_name]["out.variants_txt"]
    output:
        (_rule_kwargs[rule_name]["out.variants"] if _rule_kwargs[rule_name]["params.keep_outputs"] else temp(_rule_kwargs[rule_name]["out.variants"]))
    log:
        stderr = _rule_kwargs[rule_name]["out.stderr"]
    params:
        bin_path = getSoft(config, "fusionCatcherToVCF.py", "fusionCatcher_rule"),
        annotations_field = _rule_kwargs[rule_name]["params.annotations_field"]
    #conda:
    #    "../envs/anacore_bin.yml"
    shell:
        "{params.bin_path}"
        " --sample-name {wildcards.sample}"
        " --input-fusions {input}"
        " --output-fusions {output}"
        " 2> {log.stderr}"


del(_rule_kwargs[rule_name])
