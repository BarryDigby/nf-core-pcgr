process FORMAT_VCF {
    tag "${meta.id}:${meta.tool}"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/barryd237/pysam-xcmds:latest' :
        'docker.io/barryd237/pysam-xcmds:latest' }"

    input:
    path(fasta)
    tuple val(meta), path(vcf), path(tbi), path(cna)

    output:
    tuple val(meta), path("${prefix}.vcf.gz"), path("${prefix}.vcf.gz.tbi"), path(cna), emit: files

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}.${meta.tool}"
    """
    reformat_vcf.py \
        reformat_vcf \
        -vcf_file $vcf \
        -out ${prefix}.vcf \
        -reference $fasta
    """
}

process FORMAT_CNA {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/barryd237/pysam-xcmds:latest' :
        'docker.io/barryd237/pysam-xcmds:latest' }"

    input:
    tuple val(meta), path(vcf), path(tbi), path(cna)

    output:
    tuple val(meta), path(vcf), path(tbi), path("${meta.id}.*.tsv"), emit: files

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    reformat_cna.py \
        reformat_cna \
        -cna_file $cna \
        -sample $prefix
    """
}
