
process Sam2Bam {

    cpus   params.threads
    memory params.memory
    publishDir params.publishdir, mode: params.publishmode

    if(workflow.profile.contains('conda'))  { conda "$params.environment" }
    if(workflow.profile.contains('docker')) { container "$params.container" }
    if(workflow.profile.contains('singularity')) { container "$params.container" }

    input:
    tuple val(sample_id), path(sam)
        
    output:
    path("${sample_id}.bam"), emit: bam
    
    script: 
    """
    samtools view -@ $task.cpus -o ${sample_id}.bam $sam
    """                

}