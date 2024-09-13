/*
Here are described all processes related to python.
*/
 

// This process trim reads
process write_output_tables {
    label 'python' 
    tag "${sample}" 
    publishDir "${params.outdir}/metrics", pattern: "*", mode: 'copy' // I want all sub-directories

    input:
        tuple val(sample), path(breseq_json)

    output:
        path("*filterin.counts.txt"), emit: metric_counts
        tuple val(sample), path("*filterin.counts.txt"), emit: tuple_sample_metric_counts

    script:

    """
    write_output_tables.py ${sample} ${breseq_json} ${sample}_refs.percents.txt ${params.table_threshold} --output_counts ${sample}_filterin.counts.txt
    """

}