process SIERRALOCAL {
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(pair_id), path(cns_seq)

    output:
    tuple val(pair_id), path('consensus*.json'), emit: cns_json

    script:
    """
    sierralocal $cns_seq -o consensus_${pair_id}.json -xml ${params.xml}
    """
}
