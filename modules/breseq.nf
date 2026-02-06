/*
 * Variant calling using breseq.
 * Breseq: https://barricklab.org/twiki/bin/view/Lab/ToolsBacterialGenomeResequencing
 */

process BRESEQ_VARIANT_CALLING { 
    label 'breseq'
    tag "Mutation prediction $sample_id on $genome_file"
    
    publishDir "$params.outdir/05.called_variants", mode: 'copy', pattern: "${sample_id}/output/*"
    publishDir "$params.outdir/04.unmapped_reads/viral", mode: 'copy', saveAs: { filename ->
    filename = filename.replaceAll(/^.*\//, '')  // remove the path
    filename.contains('unmatched') ? filename.replaceAll('_unmatched', '').replaceAll(/\.fq\.unmatched/, '.unmatched') : null } // renamme files by removing '_unmatched' and changing '.fq.unmatched' to '.unmatched'
    publishDir "$params.outdir/03.aligned_reads/viral", mode: 'copy', saveAs: { filename ->
    filename = filename.replaceAll(/^.*\//, '') 
    filename.contains('reference.bam') ? filename.replaceAll('reference', "${sample_id}") : null }

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
