process HYDRA {
    tag "$pairId"
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(pairId), path(reads)

    output:
    tuple val(pairId), path('consensus_*.fasta'), emit: cns_sequence
    tuple val(pairId), path('dr_report_*.csv'), emit: dr_report
    tuple val(pairId), path('mutation_report_*.aavf'), emit: mutation_report
    tuple val(pairId), path('filtered_*.fastq'), emit: filtered

    script:
    """
    quasitools hydra ${reads} -o . --generate_consensus \
    --reporting_threshold ${params.reporting_threshold} \
    --consensus_pct ${params.consensus_pct} \
    --length_cutoff ${params.length_cutoff} \
    --score_cutoff ${params.score_cutoff} \
    --min_variant_qual ${params.min_variant_qual} \
    --min_dp ${params.min_dp} \
    --min_ac ${params.min_ac} \
    --min_freq ${params.min_freq}
    mv consensus.fasta consensus_${pairId}.fasta
    mv dr_report.csv dr_report_${pairId}.csv
    mv mutation_report.aavf mutation_report_${pairId}.aavf
    mv filtered.fastq filtered_${pairId}.fastq
    """
}
