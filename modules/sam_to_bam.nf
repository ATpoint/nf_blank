
process Sam2Bam {

    cpus   params.threads
    publishDir params.publishdir, mode: params.publishmode

    input:
    tuple val(sample_id), path(sam)
        
    output:
    path("${sample_id}.bam"), emit: bam
    
    script: 
    """
    samtools view -@ $task.cpus -o ${sample_id}.bam $sam
    """                

}