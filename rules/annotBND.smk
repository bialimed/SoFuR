__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2019 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'


rule_name = "AnnotBND_kwargs"
_rule_kwargs[rule_name] = {
    # Inputs
    "in.annotations": getRuleParam(locals(), rule_name, "in.annotations", "reference/annot.gtf"),
    "in.variants": getRuleParam(locals(), rule_name, "in.variants", "structural_variants/{variant_caller}/{sample}_sv.vcf"),
    # Outputs
    "out.variants": getRuleParam(locals(), rule_name, "out.variants", "structural_variants/{variant_caller}/{sample}_sv_annotated.vcf"),
    "out.stderr": getRuleParam(locals(), rule_name, "out.stderr", "logs/structural_variants/{sample}_{variant_caller}_annot_stderr.txt"),
    # Parameters
    "params.annotations_field": getRuleParam(locals(), rule_name, "params.annotations_field", "ANN"),
    "params.keep_outputs": getRuleParam(locals(), rule_name, "params.keep_outputs", False)
}


rule AnnotBND:
    input:
        annotations = _rule_kwargs[rule_name]["in.annotations"],
        variants = _rule_kwargs[rule_name]["in.variants"],
    output:
        (_rule_kwargs[rule_name]["out.variants"] if _rule_kwargs[rule_name]["params.keep_outputs"] else temp(_rule_kwargs[rule_name]["out.variants"]))
    log:
        stderr = _rule_kwargs[rule_name]["out.stderr"]
    params:
        bin_path = getSoft(config, "annotBND.py", "annotation_rule"),
        annotations_field = _rule_kwargs[rule_name]["params.annotations_field"]
    #conda:
    #    "../envs/anacore_bin.yml"
    shell:
        "{params.bin_path}"
        " --annotation-field {params.annotations_field}"
        " --input-annotations {input.annotations}"
        " --input-variants {input.variants}"
        " --output-variants {output.variants}"
        " 2> {log.stderr}"


del(_rule_kwargs[rule_name])
