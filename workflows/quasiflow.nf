include { FASTQC } from '../modules/fastqc'
include { MULTIQC } from '../modules/multiqc'
include { TRIMGALORE } from '../modules/trimgalore'
include { HYDRA } from '../modules/hydra'
include { SIERRALOCAL } from '../modules/sierralocal'
include { RENDERREPORT } from '../modules/renderreport'

workflow QUASIFLOW {
    take:
    reads

    main:
    FASTQC(reads)
    TRIMGALORE(reads)
    HYDRA(TRIMGALORE.out.adaptor_trimmed)
    SIERRALOCAL(HYDRA.out.cns_sequence)
    RENDERREPORT(SIERRALOCAL.out.cns_json, params.rmd, params.rmd_static)

    MULTIQC(
        FASTQC.out.fastqc_files.collect(),
        TRIMGALORE.out.adaptor_trimmed.collect(),
        HYDRA.out.filtered.collect()
    )

    emit:
    multiqc_report = MULTIQC.out
    final_report = RENDERREPORT.out.final_report
}
