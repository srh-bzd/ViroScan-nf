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
        path("${output_name}.tsv"), emit: refs_percent_final_table

    script:

    def tables_list = []
    tables_list = metric_tables
    listBashTable = tables_list.join(" ");

    """
    echo -e "Sample\tREAD_TOT\tREAD_AFTER_TRIM\tFOUT_MATCH\tFOUT_UNMATCH\tFIN_FILTEREDOUT\tFIN_UNMATCH\tFIN_MATCH"  > ${output_name}.tsv
    for i in $listBashTable;do
        cat \$i >> ${output_name}.tsv
    done
    """

}

process concat_canard{
    label 'bash'  
    publishDir "${params.outdir}/metrics", pattern: "*", mode: 'copy' // I want all sub-directories

    input:
        tuple val(sample), path (raw_reads) , path (trimmed_reads), path (unmatched), path (matched), path (in_counts)

    output:
        path("${sample}_final_table.tsv"), emit: sample_final_table

    script:
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
    FIN_MATCH=\$(awk '{print \$3}'  ${in_counts})
    FIN_UNMATCH=\$(awk '{print \$2}'  ${in_counts})
    FIN_UNMATCH=\$((\$FIN_UNMATCH - \$FIN_MATCH))

    # NB filtered out by breseq
    FIN_FILTEREDOUT=\$((\$FILTER_OUT_UNMATCH - \$FIN_UNMATCH ))

    echo -e "$sample\t\$READ_TOTAL\t\$READ_TOTAL_TRIMMED\t\$FILTER_OUT_MATCH\t\$FILTER_OUT_UNMATCH\t\$FIN_FILTEREDOUT\t\$FIN_UNMATCH\t\$FIN_MATCH" >> ${sample}_final_table.tsv

    """

}