/*
 * Conversion of SAM to sorted BAM using Samtools.
 * SAMtools: http://www.htslib.org/
 */

process SAMTOOLS_CONVERT_AND_SORT {
    label 'samtools'
    tag "Converting $sample_id SAM to BAM and sort"
    
    publishDir "$params.outdir/03.aligned_reads/host", mode: 'copy'

    input:
    tuple val(sample_id), path("${sample_id}_bowtie2.sam")

    output:
    path("${sample_id}.bam")

    script:
    """
        samtools view -@ ${task.cpus} -bS ${sample_id}_bowtie2.sam | samtools sort -@ ${task.cpus} -o ${sample_id}.bam
    
        rm -f ${sample_id}_bowtie2.sam
    """
}
