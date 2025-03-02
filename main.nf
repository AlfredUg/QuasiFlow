#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { QUASIFLOW } from './workflows/quasiflow'

// Parameter definitions (keep existing ones)

// Main workflow
workflow {
    // Input channel
    Channel
        .fromFilePairs(params.reads)
        .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
        .set { read_pairs_ch }

    QUASIFLOW(read_pairs_ch)
}

// On completion (keep existing handler)
workflow.onComplete {
    // ...
}
