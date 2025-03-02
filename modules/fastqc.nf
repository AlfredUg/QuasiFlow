process FASTQC {
    tag "$pairId"
    publishDir "${params.outdir}/qcresults-raw-reads", mode: "copy", overwrite: false

    input:
    tuple val(pairId), path(in_fastq)

    output:
    path "${pairId}_fastqc/*.zip", emit: fastqc_files

    script:
    """
    mkdir ${pairId}_fastqc
    fastqc --outdir ${pairId}_fastqc \
    ${in_fastq[0]} \
    ${in_fastq[1]}
    """
}
