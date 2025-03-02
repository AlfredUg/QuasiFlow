process RENDERREPORT {
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(pair_id), path(cns_json)
    path rmd
    path rmd_static

    output:
    tuple val(pair_id), path('hivdr_*.html'), path('hivdr_*.pdf'), emit: final_report

    script:
    """
    Rscript -e 'rmarkdown::render("${rmd}",
    params=list(
    mutation_comments="${params.mutation_db_comments}",
    dr_report_hivdb="${params.outdir}/${cns_json}",
    mutational_threshold=${params.min_freq},
    minimum_read_depth=${params.min_dp},
    minimum_percentage_cons=${params.consensus_pct}
    ),
    output_file="hivdr_${pair_id}.html", output_dir = getwd())'

    Rscript -e 'rmarkdown::render("${rmd_static}",
    params=list(
    mutation_comments="${params.mutation_db_comments}",
    dr_report_hivdb="${params.outdir}/${cns_json}",
    mutational_threshold=${params.min_freq},
    minimum_read_depth=${params.min_dp},
    minimum_percentage_cons=${params.consensus_pct}
    ),
    output_file="hivdr_${pair_id}.pdf", output_dir = getwd())'
    """
}
