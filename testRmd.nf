
params.reads = "$baseDir/test/*{1,2}.fastq"
params.rmd = "$baseDir/hivdr.Rmd"
params.outdir = "$baseDir/results"

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { read_pairs_ch }
 
process runHydra{
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(pair_id), path(reads) from read_pairs_ch

    output:
    tuple val(pair_id), path('consensus_*.fasta') into cns_sequence_ch
    tuple val(pair_id), path('dr_report_*.csv') into dr_report_ch

    script:
    """
    quasitools hydra $reads -o . --generate_consensus
    mv consensus.fasta consensus_${pair_id}.fasta 
    mv dr_report.csv dr_report_${pair_id}.csv
    """
}

process runSierralocal {
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(pair_id), path(cns_seq) from cns_sequence_ch

    output:
    tuple val(pair_id), path('consensus*_results.json') into cns_json_ch

    script:
    """
    python3 ~/sierra-local/bin/sierralocal $cns_seq
    """
}

process renderReport{
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(pair_id), path(cns_json) from cns_json_ch
    tuple val(pair_id), path(dr_report) from dr_report_ch
    path rmd from params.rmd

    output:
    tuple val(pair_id), path('hivdr_*.html') into final_report_ch

    script:
    """
    Rscript -e 'rmarkdown::render("${rmd}", output_file="hivdr_${pair_id}.html", output_dir = getwd())'
    """
}
