/*
========================================================================================
    INPUTS AND VALIDATION
========================================================================================
*/

include { validateParameters; paramsHelp; paramsSummaryLog; fromSamplesheet } from 'plugin/nf-validation'


// Validate input parameters
validateParameters()

// Print summary of supplied parameters
log.info paramsSummaryLog(workflow)


ch_short_reads = Channel.fromSamplesheet("input")
        .branch { sample, fastq_1, fastq_2 -> 
            // Paired-end
            pe: fastq_2
                new_meta = [id:sample] + [single_end:false]
                return tuple(new_meta, [ fastq_1, fastq_2 ])
            // Single end
            se: !fastq_2
                new_meta = [id:sample] + [single_end:true]
                return tuple(new_meta, [ fastq_1 ])
        }
        .mix()

/*
========================================================================================
    CONFIGS
========================================================================================
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = Channel.empty()
ch_multiqc_logo            = Channel.empty()
ch_multiqc_custom_methods_description = file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { SHORTREAD_PREPROCESSING       } from '../subworkflows/local/shortread_preprocessing'
include { FASTQC                        } from '../modules/nf-core/fastqc'
include { MULTIQC                       } from '../modules/nf-core/multiqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS   } from '../modules/custom/dumpsoftwareversions/main'

workflow MAIN_WORKFLOW {

    ch_versions = Channel.empty()
    
    // MODULE: FastQC
    
    if(!params.skip_fastqc) {
        FASTQC (
            ch_short_reads
        )
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    }

    // Subworkflow: Preprocessing
    
    if (!params.skip_preprocessing) {
        ch_shortreads_preprocessed = SHORTREAD_PREPROCESSING ( ch_short_reads, [] ).reads
        ch_versions = ch_versions.mix( SHORTREAD_PREPROCESSING.out.versions )
    } else {
        ch_shortreads_preprocessed = ch_short_reads
    }



    /*
    ====================================================================================
        FINALIZE
    ====================================================================================
    */
    
    // MODULE: SOFTWARE VERSIONS
    
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
    
    // MODULE: MultiQC
    if(!params.skip_multiqc) {
        ch_multiqc_files = Channel.empty()
        ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
        
        if(!params.skip_fastqc) {
            ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
        }
    
        MULTIQC (
            ch_multiqc_files.collect(),
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList()
        )
        multiqc_report = MULTIQC.out.report.toList()
    }

}