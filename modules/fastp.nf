/*
 * Trimming and quality control of FASTQ files using fastp.
 * fastp: https://github.com/OpenGene/fastp
 */

process FASTP_TRIMMING {
    label 'fastp'
    tag "Trimming ${sample_id}"

    publishDir "${params.outdir}/01.cleaned_reads", mode: 'copy', pattern: "*.fastq.gz"
    publishDir "${params.outdir}/01.cleaned_reads/log", mode: 'copy', pattern: "*.json"

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}*.fastq.gz"), emit: trimmed_reads
    path "${sample_id}_fastp.json", emit: fastp_report

    script:
    if (params.paired_end) {
        """
        fastp \\
            -i ${reads[0]} \\
            -I ${reads[1]} \\
            -o ${sample_id}_R1.fastq.gz \\
            -O ${sample_id}_R2.fastq.gz \\
            -w ${task.cpus} \\
            -j ${sample_id}_fastp.json \\
            ${params.fastp_options}
        """
    } else {
        """
        fastp \\
            -i ${reads} \\
            -o ${sample_id}.fastq.gz \\
            -w ${task.cpus} \\
            -j ${sample_id}_fastp.json \\
            ${params.fastp_options}
        """
    }
}
