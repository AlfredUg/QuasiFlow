#!/usr/bin/env nextflow
/*
========================================================================================
                              Q U A S I F L O W  P I P E L I N E
========================================================================================
              
              A Nextflow pipeline for analysis of NGS-based HIV Drug resitance data
               
----------------------------------------------------------------------------------------
*/

def helpMessage() {
    log.info"""
    ============================================================
    AlfredUg/QuasiFlow  ~  version ${params.version}
    ============================================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run AlfredUg/QuasiFlow --reads <path to fastq files> --outdir <path to output directory>
    
    Mandatory arguments:
      --reads                        Path to input data (must be surrounded with quotes)
      --outdir                       Path to directory where results will be saved 

    HyDRA arguments (optional):
      --mutation_db		      Path to mutational database.
      --reporting_threshold	      Minimum mutation frequency percent to report.
      --consensus_pct		      Minimum percentage a base needs to be incorporated into the consensus sequence.
      --trim_reads		      Iteratively trim reads based on filter values if enabled. Remove reads which do not meet filter values if disabled.
      --min_read_qual	              Minimum quality for a position in a read to be masked.	     
      --length_cutoff	              Reads which fall short of the specified length will be filtered out.
      --score_cutoff		      Reads that have a median or mean quality score (depending on the score type specified) less than the score cutoff value will be filtered out.
      --min_variant_qual             Minimum quality for variant to be considered later on in the pipeline.
      --min_dp                       Minimum required read depth for variant to be considered later on in the pipeline.
      --min_ac                       The minimum required allele count for variant to be considered later on in the pipeline
      --min_freq                     The minimum required frequency for mutation to be considered in drug resistance report.

    Sierralocal arguments (optional):
      --xml                          Path to HIVdb ASI2 XML.
      --apobec-tsv                   Path to tab-delimited (tsv) HIVdb APOBEC DRM file.
      --comments-tsv                 Path to tab-delimited (tsv) HIVdb comments file.
    
    Trimming arguments (optional):
      --quality        	      Trim low-quality ends from reads in addition to adapter removal.                
      --max_length     	      Discard reads that are longer than <INT> bp after trimming.
      --min_length     	      Discard reads that became shorter than length INT because of either quality or adapter trimming
      --gzip                         Compress the output file with GZIP.
      
     Other arguments (optional):
      --name                         Name of the run.
      --email                        Email to receive notification once the run is done.

    """.stripIndent()
}

// Show help emssage
params.help = false
if (params.help){
    helpMessage()
    exit 0
}

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
  custom_runName = workflow.runName
}

// Header log info
log.info "============================================================"
log.info " AlfredUg/QuasiFlow   ~  version ${params.version}"
log.info "============================================================"
def summary = [:]
summary['Run Name']       = custom_runName ?: workflow.runName
summary['Reads']          = params.reads
summary['Output directory']     = params.outdir
summary['Report template']     = params.rmd
if(workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Current home']   = "$HOME"
summary['Current user']   = "$USER"
summary['Current path']   = "$PWD"
summary['Script dir']     = workflow.projectDir
summary['Config Profile'] = workflow.profile
if(params.email) {
    summary['E-mail Address'] = params.email
}
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="

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
    Rscript -e 'rmarkdown::render("${rmd}", params=list(mutation_comments="${params.mutation_db_comments}",dr_report_hydra="${params.outdir}/${dr_report}", dr_report_hivdb="${params.outdir}/${cns_json}"), output_file="hivdr_${pair_id}.html", output_dir = getwd())'
    """
}
