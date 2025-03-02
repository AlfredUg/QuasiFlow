process TRIMGALORE {
    tag "$pairId"
    publishDir "${params.outdir}/adaptors-trimmed-reads", mode: "copy", overwrite: false

    input:
    tuple val(pairId), path(in_fastq)

    output:
    tuple val(pairId), path("*.fq"), emit: adaptor_trimmed

    script:
    """
    mkdir ${pairId}
    trim_galore -q ${params.min_read_qual} --paired ${in_fastq[0]} ${in_fastq[1]} -o .
    """
}
