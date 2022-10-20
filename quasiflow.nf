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
      --mutation_db		             Path to mutational database.
      --reporting_threshold	         Minimum mutation frequency percent to report.
      --consensus_pct		         Minimum percentage a base needs to be incorporated into the consensus sequence.
      --min_read_qual	             Minimum quality for a position in a read to be masked.	     
      --length_cutoff	             Reads which fall short of the specified length will be filtered out.
      --score_cutoff		         Reads that have a median or mean quality score (depending on the score type specified) less than the score cutoff value will be filtered out.
      --min_variant_qual             Minimum quality for variant to be considered later on in the pipeline.
      --min_dp                       Minimum required read depth for variant to be considered later on in the pipeline.
      --min_ac                       The minimum required allele count for variant to be considered later on in the pipeline
      --min_freq                     The minimum required frequency for mutation to be considered in drug resistance report.

    Sierralocal arguments (optional):
      --xml                          Path to HIVdb ASI2 XML.
      --apobec-tsv                   Path to tab-delimited (tsv) HIVdb APOBEC DRM file.
      --comments-tsv                 Path to tab-delimited (tsv) HIVdb comments file.
      
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
summary['Run Name'] = custom_runName ?: workflow.runName
summary['Reads'] = params.reads
summary['Output directory'] = params.outdir
summary['Reporting threshold'] = params.reporting_threshold
summary['Consensus percentage'] = params.consensus_pct
summary['Minimum read quality'] = params.min_read_qual
summary['Length cut off'] = params.length_cutoff
summary['Score cutoff'] = params.score_cutoff
summary['Minimum variant quality'] = params.min_variant_qual
summary['Minimum depth'] = params.min_dp
summary['Minimum allele count'] = params.min_ac
summary['Minimum mutation frequency'] = params.min_freq
summary['Report template'] = params.rmd
if(workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Current home'] = "$HOME"
summary['Current user'] = "$USER"
summary['Current path'] = "$PWD"
summary['Script dir'] = workflow.projectDir
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
    tuple val(pairId), path("*.fq") into adaptor_trimmed_ch

    """
    mkdir ${pairId}
    trim_galore -q ${params.min_read_qual} --paired ${in_fastq.get(0)} ${in_fastq.get(1)} -o . 
    """
}

process runHydra{
    tag "$pairId"
    publishDir params.outdir, mode: 'copy'

    input:
    set pairId, path(reads) from adaptor_trimmed_ch
    
    output:
    tuple val(pairId), path('consensus_*.fasta') into cns_sequence_ch
    tuple val(pairId), path('dr_report_*.csv') into dr_report_ch
    tuple val(pairId), path('mutation_report_*.aavf') into dr_report_ch_2
    tuple val(pairId), path('filtered_*.fastq') into filtered_ch

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


process runSierralocal {
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'

    input:
    set pair_id, path(cns_seq) from cns_sequence_ch

    output:
    tuple val(pair_id), path('consensus*.json') into cns_json_ch

    script:
    """
    sierralocal $cns_seq -o consensus_${pair_id}.json -xml ${params.xml}
    """
}


process renderReport{
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'
    
    input:
    set pair_id, path(cns_json) from cns_json_ch
    path rmd from params.rmd
    path rmd_static from params.rmd_static 

    output:
    tuple val(pair_id), path('hivdr_*.html'), path('hivdr_*.pdf') into final_report_ch

    script:
    """
    Rscript -e 'rmarkdown::render("${rmd}", 
        params=list(
            mutation_comments="${params.mutation_db_comments}", 
            dr_report_hivdb="${params.outdir}/${cns_json}",
            mutational_threshold=${params.min_freq},
            minimum_read_depth=${params.min_dp},
            minimum_percentage_cons=${params.consensus_pct}), 
            output_file="hivdr_${pair_id}.html", output_dir = getwd())'

    Rscript -e 'rmarkdown::render("${rmd_static}", 
        params=list(
            mutation_comments="${params.mutation_db_comments}",
            dr_report_hivdb="${params.outdir}/${cns_json}",
            mutational_threshold=${params.min_freq},
            minimum_read_depth=${params.min_dp},
            minimum_percentage_cons=${params.consensus_pct}), 
            output_file="hivdr_${pair_id}.pdf", output_dir = getwd())'
    """
}
