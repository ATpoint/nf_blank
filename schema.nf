#! /usr/bin/env nextflow

/* 
        SCHEMA DEFINITION FOR PARAMS VALIDATION
        SYNTAX FOR SCHEMA PARAMS:
        schema.yourparam = [value:'', type:'', mandatory:'', allowed:'']
*/

def Map schema = [:] // don't change this line

// --------------------------------------------------------------------------------------------------------------

// generic options:
schema.min_nf_version = [value: '21.10.6', type: 'string', mandatory: true, allowed: '']


// workflow params
schema.input       = [value: './test/*.sam', type: 'string', mandatory: true, allowed:'']
schema.threads     = [value: 1, type: 'integer', mandatory: false, allowed:'']
schema.publishdir  = [value: 'results', type: 'string', mandatory: true, allowed:'']
schema.publishmode = [value: 'rellink', type: 'string', mandatory: true, allowed:['symlink', 'rellink', 'link', 'copy', 'copyNoFollow', 'move']]

// env/docker params:
schema.container = [value:'atpoint/nf_blank:v1.0', type:'string', mandatory:true, allowed:'']
schema.environment = [value:'$baseDir/environment.yml', type:'string', mandatory:'true', allowed:'']

// --------------------------------------------------------------------------------------------------------------

return schema // don't change this line
