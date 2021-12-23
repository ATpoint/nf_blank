#! /usr/bin/env nextflow

nextflow.enable.dsl=2

//=======================================================================

// Validate params and check for minimal NF version,
// (there should be no need to modify this line)
evaluate(new File("${baseDir}/functions/validate_schema_params.nf"))

//=======================================================================

// declare input channel:
ch_input = Channel
            .fromPath(params.input, checkIfExists: true)
            .map { file -> tuple(file.simpleName, file) }

// define workflow:
include{ Sam2Bam } from './modules/sam_to_bam'                                                               

workflow ExampleWorkflow {

    Sam2Bam(ch_input)

}

// run workflow:
workflow { ExampleWorkflow() }