/*
 * Alignment of reads to a reference genome indexed using Bowtie2.
 * Bowtie2: http://bowtie-bio.sourceforge.net/bowtie2/index.shtml
 */

process BOWTIE2_INDEX { 
    label 'bowtie2'
    tag "Indexing $genome_file"

    publishDir "$params.outdir/02.indexed_ref", mode: 'copy'

    input:
    path genome_file

    output:
    tuple val(genome_file.baseName), path("${genome_file.baseName}*.bt2"), emit: genome_indexed


    script:
    """
        bowtie2-build --threads ${task.cpus} \\
            ${genome_file} \\
            ${genome_file.baseName}
    """
}

process BOWTIE2_ALIGN { 
    label 'bowtie2'
    tag "Aligning $sample_id on $genome_prefix"

    publishDir "$params.outdir/03.aligned_reads/log", mode: 'copy', pattern: "*.log"
    publishDir "$params.outdir/03.aligned_reads/host", mode: 'copy', pattern: "${sample_id}_matched*fq.gz"
    publishDir "$params.outdir/04.unmapped_reads/host", mode: 'copy', pattern: "${sample_id}_unmatched*fq.gz"

    input:
    tuple val(genome_prefix), path(genome_indexed)
    tuple val(sample_id), path(reads)
    
    output:
    tuple val(sample_id), path("${sample_id}_matched*fq.gz") , emit: matched_reads
    tuple val(sample_id), path("${sample_id}_unmatched*fq.gz") , emit: unmatched_reads
    tuple val(sample_id), path("${sample_id}_bowtie2.sam"), emit: sam_file
    path "${sample_id}_bowtie2.log", emit: bowtie2_report

    script:
    if (params.paired_end) {
        """
            bowtie2 -p ${task.cpus} \\
                -x ${genome_prefix} \\
                -S ${sample_id}_bowtie2.sam \\
                -1 ${reads[0]} -2 ${reads[1]} \\
                --al-gz ${sample_id}_matched.fq.gz --un-gz ${sample_id}_unmatched.fq.gz \\
                --al-conc-gz ${sample_id}_matched_R%.fq.gz --un-conc-gz ${sample_id}_unmatched_R%.fq.gz \\
                ${params.bowtie2_options} 2> ${sample_id}_bowtie2.log
        """
    } else {
        """
            bowtie2 -p ${task.cpus} \\
                    -x ${genome_prefix} \\
                    -S ${sample_id}_bowtie2.sam \\
                    -U ${reads} \\
                    --al-gz ${sample_id}_matched.fq.gz \\
                    --un-gz ${sample_id}_unmatched.fq.gz \\
                    ${params.bowtie2_options} 2> ${sample_id}_bowtie2.log
        """
    }
}
