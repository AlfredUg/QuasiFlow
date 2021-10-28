params.reads = "$baseDir/data/*{1,2}.fastq"
params.rmd = "$baseDir/hivdr.Rmd"
params.outdir = "$baseDir/results"

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .into { read_pairs_ch_1; read_pairs_ch_2; read_pairs_ch_3 }
 
process runfastQC {
    tag "${pairId}" 
    publishDir "${params.outdir}/qcresults-raw-reads", mode: "copy", overwrite: false

    input:
    set pairId, file(in_fastq) from read_pairs_ch_1

    output:
    file("${pairId}_fastqc/*.zip") into fastqc_files

    """
    mkdir ${pairId}_fastqc
    fastqc --outdir ${pairId}_fastqc \
    ${in_fastq.get(0)} \
    ${in_fastq.get(1)}
    """
}

process runMultiQC{
    publishDir "${params.outdir}/qcresults-raw-reads", mode: "copy", overwrite: false

    input:
    file('*') from fastqc_files.collect()

    output:
    file('raw_reads_multiqc_report.html')

    """
    multiqc .
    mv multiqc_report.html raw_reads_multiqc_report.html
    """
}

process runTrimGalore {
    tag "${pairId}"
    publishDir "${params.outdir}/adaptors-trimmed-reads", mode: "copy", overwrite: false

    input:
    set pairId, file(in_fastq) from read_pairs_ch_2

    output:
    path("*.fq")  into adaptor_trimmed_ch

    """
    mkdir ${pairId}
    trim_galore -q 30 --paired ${in_fastq.get(0)} ${in_fastq.get(1)} -o . 
    """
}


process runHydra{
    tag "$pairId"
    publishDir params.outdir, mode: 'copy'

    input:
    set pairId, path(reads) from read_pairs_ch_3
    
    output:
    tuple val(pairId), path('consensus_*.fasta') into cns_sequence_ch
    tuple val(pairId), path('dr_report_*.csv') into dr_report_ch
    tuple val(pairId), path('filtered_*.fastq') into filtered_ch

    script:
    """
    quasitools hydra ${reads} -o . --generate_consensus
    mv consensus.fasta consensus_${pairId}.fasta 
    mv dr_report.csv dr_report_${pairId}.csv
    mv filtered.fastq filtered_${pairId}.fastq
    """
}


process runfastqcOnfiltered {
    tag "${pairId}"
    publishDir "${params.outdir}/qcresults-post-filtering", mode: "copy", overwrite: false

    input:
    set pairId, file(in_fastq) from filtered_ch

    output:
    file("${pairId}_fastqc/*.zip") into fastqc_files_post_filter_ch

    """
    mkdir ${pairId}_fastqc
    fastqc --outdir ${pairId}_fastqc ${in_fastq} 
    """
}

process runMultiqcOnfiltered{
    publishDir "${params.outdir}/qcresults-post-filtering", mode: "copy", overwrite: false

    input:
    file('*') from fastqc_files_post_filter_ch.collect()

    output:
    file('filtered_reads_multiqc_report.html')

    """
    multiqc .
    mv multiqc_report.html filtered_reads_multiqc_report.html
    """
}


process runSierralocal {
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(pair_id), path(cns_seq) from cns_sequence_ch

    output:
    tuple val(pair_id), path('consensus*.json') into cns_json_ch

    script:
    """
    sierralocal $cns_seq -o consensus_${pair_id}.json
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
    Rscript -e 'rmarkdown::render("${rmd}", params=list(dr_report_hydra="${params.outdir}/${dr_report}", dr_report_hivdb="${params.outdir}/${cns_json}"), output_file="hivdr_${pair_id}.html", output_dir = getwd())'
    """
}
