__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2019 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'


rule_name = "STAR_kwargs"
_rule_kwargs[rule_name] = {
    # Inputs
    "in.R1": getRuleParam(locals(), rule_name, "in.R1"),  # Required
    "in.R2": getRuleParam(locals(), rule_name, "in.R2", None),
    "in.annotations": getRuleParam(locals(), rule_name, "in.annotations", "reference/annot.gtf"),
    "in.sequences": getRuleParam(locals(), rule_name, "in.sequences", "reference/sequences.fasta"),
    # Outputs
    "out.alignments": getRuleParam(locals(), rule_name, "out.alignments", "aln/star/{sample}.bam"),
    "out.stderr": getRuleParam(locals(), rule_name, "out.stderr", "logs/aln/{sample}_star_stderr.txt"),
    # Parameters
    "params.extra": getRuleParam(locals(), rule_name, "params.extra", ""),
    "params.keep_outputs": getRuleParam(locals(), rule_name, "params.keep_outputs", False),
    "params.keep_unmapped": getRuleParam(locals(), rule_name, "params.keep_unmapped", True),
    "params.mapq_uniq": getRuleParam(locals(), rule_name, "params.mapq_uniq", 50),
    "params.nb_threads": getRuleParam(locals(), rule_name, "params.nb_threads", 10),
    "params.out_type": getRuleParam(locals(), rule_name, "params.out_type", "bam"),  # BAM or SAM
    "params.sort": getRuleParam(locals(), rule_name, "params.sort", True),
    "params.sort_buffer_size": getRuleParam(locals(), rule_name, "params.sort_buffer_size", 30),
}
_rule_kwargs[rule_name]["in.genome_dir"] = os.path.basename(_rule_kwargs[rule_name]["in.sequences"])

################## test correct output name when ort = False
################## test single-end

rule STAR:
    input:
        R1 = _rule_kwargs[rule_name]["in.R1"],
        R2 = _rule_kwargs[rule_name]["in.R2"],
        genome_dir = _rule_kwargs[rule_name]["in.genome_dir"],
        annotations = _rule_kwargs[rule_name]["in.annotations"],
    output:
        (_rule_kwargs[rule_name]["out.alignments"] if _rule_kwargs[rule_name]["params.keep_outputs"] else temp(_rule_kwargs[rule_name]["out.alignments"]))
    log:
        stderr = _rule_kwargs[rule_name]["out.stderr"]
    params:
        bin_path = getSoft(config, "STAR", "alignment_rule"),
        extra = _rule_kwargs[rule_name]["params.extra"],
        mapq_uniq = _rule_kwargs[rule_name]["params.mapq_uniq"],
        sort_buffer_size = _rule_kwargs[rule_name]["params.sort_buffer_size"] * 1000000000,
        type_arguments = _rule_kwargs[rule_name]["params.out_type"].upper() + (" SortedByCoordinate" if _rule_kwargs[rule_name]["params.sort"] else ""),
        unmapped = "--outSAMunmapped Within" if _rule_kwargs[rule_name]["params.keep_unmapped"] else ""),
        output_suffix = "Aligned.sortedByCoord.out." + _rule_kwargs[rule_name]["params.out_type"] if _rule_kwargs[rule_name]["params.sort"] else "Aligned.sortedByCoord.out." + _rule_kwargs[rule_name]["params.out_type"]
    conda:
        "../envs/star.yml"
    threads: _rule_kwargs[rule_name]["params.nb_threads"],
    shell:
        "{params.bin_path}"
        " --runThreadN {threads}"
        " {params.unmapped}"
        " {param.extra}"
        " --outSAMattributes NH NM MD"
        " --outSAMattrRGline ID:1 SM:{wildcards.sample}"
        " --outSAMmapqUnique {params.mapq_uniq}"
        " --limitBAMsortRAM {params.sort_buffer_size}"
        " --readFilesCommand zcat"
        " --outSAMtype {params.type_arguments}"
        " --readFilesIn {input.R1} {input.R2}"
        " --genomeDir {input.genome_dir}"
        " --sjdbGTFfile {input.annotations}"
        " --outFileNamePrefix `basename {output}`/{wildcards.sample}"
        " 2> {log.stderr}"
        " && "
        "mv"
        " `basename {output}`/{wildcards.sample}{params.output_suffix}"
        " {output}"
        " 2>> {log.stderr}"


del(_rule_kwargs[rule_name])
