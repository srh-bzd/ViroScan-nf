/*
Here are described all processes related to bash.
*/
 

// This process trim reads
process concat_tables {
    label 'bash'  
    publishDir "${params.outdir}/metrics", pattern: "*", mode: 'copy' // I want all sub-directories

    input:
        val(metric_tables)

    output:
        path("refs.percents.txt"), emit: refs_percent_final_table
        path("filterin.counts.txt"),  emit: filterin_count_final_table

    shell:

    def tables_list = []
    tables_list = metric_tables
    listBash = tables_list.join(" ");
    """
    echo $listBash
    """

}