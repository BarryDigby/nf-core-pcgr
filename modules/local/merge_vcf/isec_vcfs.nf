process ISEC_VCFS {
    tag "$meta"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/barryd237/pysam-xcmds:latest' :
        'docker.io/barryd237/pysam-xcmds:latest' }"

    input:
    tuple val(meta), path(vcfs)

    output:
    tuple val(meta), path("${prefix}_keys.txt"), emit: sample_keys

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta}"
    """
    python3.6 "${projectDir}/bin/isec_vcfs.py" \
        -sample ${prefix}
    """
}
