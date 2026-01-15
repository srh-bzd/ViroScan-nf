/*
 * Variant calling using breseq.
 * Breseq: https://barricklab.org/twiki/bin/view/Lab/ToolsBacterialGenomeResequencing
 */

process BRESEQ_VARIANT_CALLING { 
    label 'breseq'
    tag "Mutation prediction $sample_id on $genome_file"
    
    publishDir "$params.outdir/05.called_variants", mode: 'copy'
    publishDir "$params.outdir/04.unmapped_reads/viral", mode: 'copy', saveAs: { filename -> filename.contains('unmatched') ? filename.replaceAll(/.*\//, '') : null }
    
    input:
    path genome_file
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}/data/summary.json"), emit: breseq_json_file
    path("${sample_id}/data/*"), emit: all_data_files
    path("${sample_id}/output/*"), emit: all_output_files

    script:
    """
        breseq -r ${genome_file} \\
                ${reads} \\
                -j ${task.cpus} \\
                -o ${sample_id} \\
                ${params.breseq_options}
    """
}
