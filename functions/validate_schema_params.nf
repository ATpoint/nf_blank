#! /usr/bin/env nextflow 

nextflow.enable.dsl=2

/*********************************************  

    PARAMS VALIDATION VIA SCHEMA.NF

    TODO: Update README!!!
    TODO: Update schema.nf to work with the example workflow!

**********************************************/

def ValidateParams(){

    // ANSI escape codes to color terminal output
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
    println ""

    // VALIDATION: check first that schema.nf exists in the baseDir
    def schemafile = new File("$baseDir/schema.nf")

    if(!schemafile.exists()){
        println("$ANSI_RED")
        println "[VALIDATION ERROR] The expected \$baseDir/schema.nf file does not exist!"
        println "                   File schema.nf must be located in the same directory as the main.nf!"
        println("")
        System.exit(1)
    }

    // import schema map from schema.nf
    def schema = evaluate(schemafile)

    // parse params from schema and params (params = everything set via command line, configs, scripts etc via "standard" Nextflow)
    def schema_keys = schema.keySet()
    def params_keys = params.keySet()
    def schema_error = 0

    // VALIDATION: each param via "standard" Nextflow must be defined in schema.nf
    def diff_keys   = params_keys - schema_keys
    if(diff_keys.size()>0){
        println("$ANSI_RED" + "$DASHEDDOUBLE")
        println "[VALIDATION ERROR] The following params are not defined in schema.nf:"
        println("")
        diff_keys.each { k -> println "--${k}"}
        println("$DASHEDDOUBLE" + "$ANSI_RESET")
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
            println("$ANSI_RED" +
                    "[VALIDATION ERROR] schema.${schema_name} does not contain the four keys value/type/mandatory/allowed" +
                    "                   ==> The schema map must look like: schema.foo = [value:, type:, mandatory:, allowed:]" +
                    "$ANSI_RESET")
            schema_error += 1
            return
        }

        // VALIDATION: schema_value must be of type as defined in schema_type
        def not_type_correct           = "[VALIDATION ERROR] schema.${schema_name} is not of type $schema_type"
        def not_mandatory_correct      = "[VALIDATION ERROR] schema.${schema_name} is mandatory but not set or empty"
        def not_allowed_correct        = "[VALIDATION ERROR] the value of schema.${schema_name} is not one of $schema_allowed"
        def not_allowed_correct_type   = "[VALIDATION ERROR] entries in 'allowed' of schema.${schema_name} are not of type $schema_type"
        def not_allowed_type           = "[VALIDATION ERROR] schema.${schema_name} must be one of $schema_allowed"
                                                        
        if(schema_type=="integer"){
            if((schema_value !instanceof Integer) && (schema_value !instanceof Long)){
                println("$ANSI_RED" + "$DASHEDDOUBLE")
                println("$not_type_correct")
                println("=> Did you accidentally wrap the number in quotes or passed a float?")
                println("$DASHEDDOUBLE" + "$ANSI_RESET")
                schema_error += 1
                return
            }                 
        }

        if(schema_type=="float"){
            if((schema_value !instanceof Double) && (schema_value !instanceof Float) && (schema_value !instanceof BigDecimal)){
                println("$ANSI_RED" + "$DASHEDDOUBLE")
                println("$not_type_correct")
                println("=> Did you accidentally wrap the number in quotes or passed an integer?")
                println("$DASHEDDOUBLE" + "$ANSI_RESET")
                schema_error += 1
                return
            }                 
        }

        if(schema_type=="string"){
            if(schema_value !instanceof String){
                println("$ANSI_RED" + "$DASHEDDOUBLE")
                println("$not_type_correct")
                println("=> Did you forget to wrap the value in quotes?")
                println("$DASHEDDOUBLE" + "$ANSI_RESET")
                schema_error += 1
                return
            }                 
        }

        if(schema_type=="logical"){
            if(schema_value !instanceof Boolean){
                println("$ANSI_RED" + "$DASHEDDOUBLE")
                println("$not_type_correct")
                println("=> Remember, it must be true/false without quotes, not \"true\"/\"false\"")
                println("$DASHEDDOUBLE" + "$ANSI_RESET")
                schema_error += 1
                return
            }                 
        }

        // VALIDATION: schema_allowed choices contain the default 'value'
        if(schema_allowed!=''){
            if(!schema_allowed.contains(schema_value)){
                println("$ANSI_RED" + "$DASHEDDOUBLE")
                println("$not_allowed_type")
                println("=> See the 'allowed' key in the schema.${schema_name} map in schema.nf")
                println("$DASHEDDOUBLE" + "$ANSI_RESET")
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
                    println("$ANSI_RED" +
                        "$not_allowed_correct_type" +
                        "$ANSI_RESET")
                schema_error += 1
                return
                }
            }
            
        }

        // VALIDATION: if schema_mandatory is true then schema_value must not be empty
        if(schema_mandatory){
            if(schema_value=='' || schema_value==null) { 
                println("$ANSI_RED" +
                        not_mandatory_correct +
                        "$ANSI_RESET")
                schema_error += 1
                return
            } 
        }

        params[schema_name] = schema_value

    }

    if(schema_error > 0){

        def was_were = schema_error==1 ? "was" : "were"
        def xerrors = schema_error==1 ? "error" : "errors"
        println ""
        println("$ANSI_RED" + "$DASHEDDOUBLE")
        println "||                                                                  ||"
        println "||                                                                  ||"
        println("||          [EXIT ON ERROR] Parameter validation failed!            ||")
        println "||                                                                  ||"
        println("||      There $was_were a total of $schema_error validation $xerrors for schema.nf!    ||")
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