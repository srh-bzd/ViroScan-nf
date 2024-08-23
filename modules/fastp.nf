/*
Here are described all processes related to fastp
fastp is a tool designed to provide fast all-in-one preprocessing for FastQ files.
See https://github.com/OpenGene/fastp
*/
 

// This process trim reads
process fastp {
    label 'fastp' 
    tag "$sample" 
    publishDir "${params.outdir}/fastp_analysis", pattern: "*", mode: 'copy' // I want all sub-directories

    input:
        tuple val(sample), path(reads)

    output:
        tuple val(sample), path ("*.trimmed.fq.gz"), emit: tuple_sample_fastq_trimmed
        path "*fastp.json",  emit: fastp_summary

    script:

    if (params.single_end){
    """
        fastp -i ${reads} \\
              -w ${task.cpus} \\
              -o ${sample}.trimmed.fq.gz \\
              --cut_right \\
              -j ${sample}_fastp.json
    """
    } else {
    """
        fastp -i ${reads[0]} -I ${reads[1]} \\
              -w ${task.cpus} \\
              -o ${sample}_R1.trimmed.fq.gz \\
              -O ${sample}_R1.trimmed.fq.gz \\
              --cut_right \\
              -j ${sample}_fastp.json
    """
    }

}