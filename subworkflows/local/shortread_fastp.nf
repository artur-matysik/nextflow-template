//
// Process short raw reads with FastP
//

include { FASTP as FASTP_SINGLE       } from '../../modules/nf-core/fastp/main'
include { FASTP as FASTP_PAIRED       } from '../../modules/nf-core/fastp/main'

workflow SHORTREAD_FASTP {
    take:
    reads // [[meta], [reads]]
    adapterlist

    main:
    ch_versions           = Channel.empty()
    ch_multiqc_files      = Channel.empty()

    ch_input_for_fastp = reads
                            .branch{
                                single: it[0]['single_end'] == true
                                paired: it[0]['single_end'] == false
                            }

    FASTP_SINGLE ( ch_input_for_fastp.single, adapterlist, false, false )
    // Last parameter here turns on merging of PE data
    FASTP_PAIRED ( ch_input_for_fastp.paired, adapterlist, false, false )

    ch_fastp_reads_prepped = FASTP_PAIRED.out.reads
                                    .mix( FASTP_SINGLE.out.reads )
    

    ch_versions = ch_versions.mix(FASTP_SINGLE.out.versions.first())
    ch_versions = ch_versions.mix(FASTP_PAIRED.out.versions.first())

    ch_processed_reads = ch_fastp_reads_prepped

    ch_multiqc_files = ch_multiqc_files.mix( FASTP_SINGLE.out.json )
    ch_multiqc_files = ch_multiqc_files.mix( FASTP_PAIRED.out.json )

    emit:
    reads    = ch_processed_reads   // channel: [ val(meta), [ reads ] ]
    versions = ch_versions          // channel: [ versions.yml ]
    mqc      = ch_multiqc_files
}