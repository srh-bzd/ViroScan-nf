/*
Here are described all processes related to bowtie2
Bowtie 2 is an ultrafast and memory-efficient tool for aligning sequencing reads to long reference sequences. 
See https://bowtie-bio.sourceforge.net/bowtie2/index.shtml
*/

// This process index a fasta sequence
process bowtie2_index {
    label 'bowtie2' 
    tag "$genome_fasta" 
    publishDir "${params.outdir}/Bowtie2_indicies", mode: 'copy'

    input:
    path(genome_fasta)

    output:
    path('*.bt2')

    script:
    """
    bowtie2-build --threads ${task.cpus} $genome_fasta ${genome_fasta.baseName}
    """
}

// This process align reads against a fasta reference indexed
process bowtie2 {
    label 'bowtie2' 
    tag "$sample" 
    publishDir "${params.outdir}/Bowtie2_alignments/matched", pattern: "*_matched.fq.gz", mode: 'copy' 
    publishDir "${params.outdir}/Bowtie2_alignments/unmatched", pattern: "*_unmatched.fq.gz", mode: 'copy' 

    input:
        tuple val(sample), path(reads)
        path bowtie2_index
        path genome

    output:
        tuple val(sample), path ("*_unmatched*fq.gz"), emit: tuple_sample_fastq
        path "*bowtie2.log",  emit: bowtie2_summary
        tuple val(sample), path("*_matched*fq.gz"), emit: tuple_sample_fastq_matched

    script:

    if (params.single_end){
    """
        bowtie2 ${params.bowtie2_options} \\
                -p ${task.cpus} \\
                -x ${genome.baseName} \\
                -S ${sample}_bowtie2.sam \\
                -U ${reads} \\
                --al-gz ${sample}_matched.fq.gz \\
                --un-gz ${sample}_unmatched.fq.gz 2> ${reads.baseName}_bowtie2.log
    """
    } else {
    """
        bowtie2 ${params.bowtie2_options} \\
            -p ${task.cpus} \\
            -x ${genome.baseName} \\
            -S ${sample}_bowtie2.sam \\
            -1 ${reads[0]} -2 ${reads[1]} \\
            --al-gz ${sample}_matched.unpaired.fq.gz --un-gz ${sample}_unmatched.unpaired.fq.gz \\
            --al-conc-gz ${sample}_matched_R%.paired.fq.gz --un-conc-gz ${sample}_unmatched_R%.paired.fq.gz 2> ${reads[0].baseName}_bowtie2.log
    """
    }

}