#! /usr/bin/env nextflow

nextflow.enable.dsl=2

//=======================================================================

// Validate params (there should be no need to modify this line)
evaluate(new File("${baseDir}/functions/validate_schema_params.nf"))

//=======================================================================

// declare input channel:
ch_input = Channel
            .fromPath(params.input, checkIfExists: true)
            .map { file -> tuple(file.simpleName, file) }

// define workflow:
workflow ExampleWorkflow {

    include{ Sam2Bam } from './modules/sam_to_bam'                                                               

    Sam2Bam(ch_input)

}

// run workflow:
workflow { ExampleWorkflow() }