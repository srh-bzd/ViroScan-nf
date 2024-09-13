/*
Here are described all processes related to bash.
*/
 

// This process trim reads
process concat_tables {
    label 'bash'  
    publishDir "${params.outdir}/metrics", pattern: "*", mode: 'copy' // I want all sub-directories

    input:
        path(metric_tables)
        val output_name

    output:
        path("${output_name}.txt"), emit: refs_percent_final_table

    script:

    def tables_list = []
    tables_list = metric_tables
    listBashTable = tables_list.join(" ");

    """
    echo -e "Sample\tREAD_TOTAL\tFILTER_OUT_UNMATCH\tFILTER_OUT_MATCH\tNB_READS_TO_ALIGN\tNB_READS_ALIGNED"  > ${output_name}.txt
    for i in $listBashTable;do
        cat \$i >> ${output_name}.txt
    done
    """

}

process concat_canard{
    label 'bash'  
    publishDir "${params.outdir}/metrics", pattern: "*", mode: 'copy' // I want all sub-directories

    input:
        tuple val(sample), path (raw_reads)
        tuple val(sample), path (trimmed_reads)
        tuple val(sample), path (unmatched)
        tuple val(sample), path (matched)
        tuple val(sample), path (in_counts)

    output:
        path("${sample}_final_table.txt"), emit: sample_final_table

    script:
    log.info"""
        ${sample} ${raw_reads}
        ${sample} ${trimmed_reads}
        ${sample} ${unmatched}
        ${sample} ${matched}
        ${sample} ${in_counts}
    """
    """
    # work with raw fastq files input
    nb_read=\$(zcat ${raw_reads} | wc -l)
    READ_TOTAL=\$((\$nb_read/4))

    # work with fastq files trimmed
    nb_read=\$(zcat ${trimmed_reads} | wc -l)
    READ_TOTAL_TRIMMED=\$((\$nb_read/4))

    # Work with fastq files output
    nb_read=\$(zcat ${unmatched} | wc -l)
    FILTER_OUT_UNMATCH=\$((\$nb_read/4)) 
    nb_read=\$(zcat ${matched} | wc -l)
    FILTER_OUT_MATCH=\$((\$nb_read/4)) 

    # Work with table from breseq output
    NB_READS_TO_ALIGN=\$(awk '{print \$2}'  ${in_counts})
    NB_READS_ALIGNED=\$(awk '{print \$3}'  ${in_counts})
    echo -e "$sample\t\$READ_TOTAL\t\$READ_TOTAL_TRIMMED\t\$FILTER_OUT_UNMATCH\t\$FILTER_OUT_MATCH\t\$NB_READS_TO_ALIGN\t\$NB_READS_ALIGNED" >> ${sample}_final_table.txt

    """

}