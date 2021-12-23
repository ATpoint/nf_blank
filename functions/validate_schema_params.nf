#! /usr/bin/env nextflow 

nextflow.enable.dsl=2

/*********************************************  

    PARAMS VALIDATION VIA SCHEMA.NF

**********************************************/

// function for printing consistent error messages:
def ErrorMessenger(base_message='', additional_message=''){
    println("$ANSI_RED" + "$DASHEDDOUBLE")
    println("[VALIDATION ERROR] $base_message")
    if(additional_message!='') { println("$additional_message") }
    println("$DASHEDDOUBLE" + "$ANSI_RESET")
}

// validation function:
def ValidateParams(){

    // ANSI escape codes to pretty colored terminal output
    ANSI_RESET   = "\u001B[0m"
    ANSI_BLACK   = "\u001B[30m"
    ANSI_RED     = "\u001B[31m"
    ANSI_GREEN   = "\u001B[32m"
    ANSI_YELLOW  = "\u001B[33m"
    ANSI_BLUE    = "\u001B[34m"
    ANSI_PURPLE  = "\u001B[35m"
    ANSI_CYAN    = "\u001B[36m"
    ANSI_WHITE   = "\u001B[37m"
    DASHEDDOUBLE  = "=".multiply(70)
    println "" // empty line so first message is not bunched to the nextflow stdout stuff

    /* START VALIDATION */
    // VALIDATION: check first that schema.nf exists in the baseDir
    def schemafile = new File("$baseDir/schema.nf")

    if(!schemafile.exists()){
        ErrorMessenger("The expected \$baseDir/schema.nf file does not exist!",
                       "=> File 'schema.nf' must be located in the same directory as the main.nf!")
        System.exit(1)
    }

    // import schema map from schema.nf
    def schema = evaluate(schemafile)

    // parse params from schema and params (params = everything set via command line, configs, scripts etc so "standard" Nextflow)
    def schema_keys = schema.keySet()
    def params_keys = params.keySet()
    def schema_error = 0

    // VALIDATION: each param via "standard" Nextflow must be defined in schema.nf
    def diff_keys   = params_keys - schema_keys
    if(diff_keys.size()>0){
        ErrorMessenger("The following params are not defined in schema.nf:",
                       diff_keys.each { k -> println "--${k}"})
        schema_error += 1
    }
    
    // go through each schema param:
    schema.each { schema_name, entry -> 
    
        // if there is a param (from command line, config, script, params-file etc. then use this rather than the schema 'value')
        if(params.keySet().contains(schema_name)){
            schema_value     = params[schema_name]
        } else schema_value  = entry['value']

        def schema_type      = entry['type']
        def schema_allowed   = entry['allowed']
        def schema_mandatory = entry['mandatory']

        // VALIDATION: schema map must have the four keys
        def keys_diff = ["value", "type", "mandatory", "allowed"] - entry*.key
        if(keys_diff.size() > 0){
            ErrorMessenger("schema.${schema_name} does not contain the four keys value/type/mandatory/allowed",
                           "=> The schema map must look like: schema.foo = [value:, type:, mandatory:, allowed:]")
            schema_error += 1
            return
        }

        // VALIDATION: schema_value must be of type as defined in schema_type and schema_type must be of of type_choices
        // (this below could use some cleanup...)
        def not_type_correct           = "schema.${schema_name} is not of type $schema_type"
        def type_choices               = ['integer', 'float', 'numeric', 'string', 'logical']
        def not_type_allowed           = "The 'type' key in schema.${schema_name} must be one of:"
        def not_mandatory_correct      = "schema.${schema_name} is mandatory but not set or empty"
        def not_allowed_correct        = "The value of schema.${schema_name} is not one of $schema_allowed"
        def not_allowed_correct_type   = "Entries in 'allowed' of schema.${schema_name} are not of type $schema_type"
        def not_allowed_type           = "schema.${schema_name} must be one of: \n${schema_allowed}"

        // check that schema_type is any of type_choices
        def valid_type = type_choices.contains(schema_type)
        if(!valid_type){
            ErrorMessenger(not_type_allowed, type_choices)
            schema_error += 1
            return
        }

        if(schema_type=="integer"){
            if((schema_value !instanceof Integer) && (schema_value !instanceof Long)){
                ErrorMessenger(not_type_correct, "=> You provided: $schema_value")
                schema_error += 1
                return
            }
        }                 
            
        if(schema_type=="float"){
            if((schema_value !instanceof Double) && (schema_value !instanceof Float) && (schema_value !instanceof BigDecimal)){
                ErrorMessenger(not_type_correct, "=> You provided: $schema_value")
                schema_error += 1
                return
            }                 
        }

        if(schema_type=="numeric"){
            if((schema_value !instanceof Integer) && (schema_value !instanceof Long) &&
               (schema_value !instanceof Double) && (schema_value !instanceof Float) && 
               (schema_value !instanceof BigDecimal)){
                ErrorMessenger(not_type_correct, "=> You provided: $schema_value")
                schema_error += 1
                return
            }                 
        }                                  

        if(schema_type=="string"){
            if(schema_value !instanceof String){
                ErrorMessenger(not_type_correct, "=> You provided: $schema_value")
                schema_error += 1
                return
            }                 
        }

        if(schema_type=="logical"){
            if(schema_value !instanceof Boolean){
                ErrorMessenger(not_type_correct, "=> You provided: $schema_value")
                schema_error += 1
                return
            }                 
        }

        // VALIDATION: schema_allowed choices contain the default 'value'
        if(schema_allowed!=''){
            if(!schema_allowed.contains(schema_value)){
                ErrorMessenger(not_allowed_type, 
                               "=> See the 'allowed' key in the schema.${schema_name} map in schema.nf")
                schema_error += 1
                return
            }
        }
        
        // VALIDATION: schema_allowed choices must be of same 'type' as 'value'
        if(schema_allowed!=''){
            def value_class = schema_value.getClass()
            schema_allowed.each { 
                def current_class = it.getClass()
                if(current_class != value_class) {
                    ErrorMessenger(not_allowed_correct_type) 
                    schema_error += 1
                    return
                }
            }  
        }

        // VALIDATION: if schema_mandatory is true then schema_value must not be empty
        if(schema_mandatory){
            if(schema_value=='' || schema_value==null) {
                ErrorMessenger(not_mandatory_correct) 
                schema_error += 1
                return
            } 
        }

        params[schema_name] = schema_value

    }

    // print error summary message:
    if(schema_error > 0){

        def was_were = schema_error==1 ? "was" : "were"
        def spacer = was_were=="was" ? "      " : "    "
        def xerrors = schema_error==1 ? "error" : "errors"
        println("$ANSI_RED" + "$DASHEDDOUBLE")
        println "||                                                                  ||"
        println "||                                                                  ||"
        println("||          [EXIT ON ERROR] Parameter validation failed!            ||")
        println "||                                                                  ||"
        println("||      There $was_were a total of $schema_error validation $xerrors for schema.nf!${spacer}||")
        println "||                                                                  ||"
        println "||                                                                  ||"
        println("$DASHEDDOUBLE" + "$ANSI_RESET")

        System.exit(1)     

    } else {

        println("$ANSI_YELLOW" + 
                "" +
                "[Info] Parameter validation passed!" +
                "$ANSI_RESET")

    }

    // VALIDATION: minimal nf version:
    if( !nextflow.version.matches(">=${params.min_nf_version}") ) {
        println ""
        println "$ANSI_RED" + "$DASHEDDOUBLE"
        println "[VERSION ERROR] This workflow requires Nextflow version ${params.min_nf_version}"
        println "=> You are running version $nextflow.version."
        println "=> Use NXF_VER=${params.min_nf_version} nextflow run (...)"
        println "$DASHEDDOUBLE ${ANSI_RESET}"
        System.exit(1)
    }

    // print params summary with adaptive spacing so columns are properly aligned regardless of param name
    def max_char = params.keySet().collect { it.length() }.max()  
    println ""
    println "$ANSI_YELLOW" + "$DASHEDDOUBLE"
    println ""
    println "${ANSI_GREEN}[PARAMS SUMMARY]${ANSI_RESET}"
    println ""
    params.each { k, v -> 
        
        def use_length = max_char - k.length()
        def spacer = ' '.multiply(use_length)
        println "${ANSI_GREEN}${k} ${spacer}:: ${ANSI_GREEN}${v}${ANSI_RESET}" 

    }
    println ""
    println "${ANSI_YELLOW}${DASHEDDOUBLE}"
    println "$ANSI_RESET"

}

/*
   this script is evaluate()-ed in main.nf so we run the function here and then import params 
   so it is available in the global main.nf environment
*/
ValidateParams()
return(params)
