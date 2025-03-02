process MULTIQC {
    publishDir "${params.outdir}/qcresults-raw-reads", mode: "copy", overwrite: false

    input:
    path('*')

    output:
    path 'raw_reads_multiqc_report.html'

    script:
    """
    multiqc .
    mv multiqc_report.html raw_reads_multiqc_report.html
    """
}
