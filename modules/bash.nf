/*
Here are described all processes related to bash.
*/
 

// This process trim reads
process concat_tables {
    label 'bash'  
    publishDir "${params.outdir}/metrics", pattern: "*", mode: 'copy' // I want all sub-directories

    input:
        path(metric_tables)

    output:
        path("refs.percents.txt"), emit: refs_percent_final_table

    script:

    def tables_list = []
    tables_list = metric_tables
    listBashTable = tables_list.join(" ");
    log.info"""
    $listBashTable
    """
    """
    for i in $listBashTable;do
        cat \$i >> refs.percents.txt
    done
    """

}