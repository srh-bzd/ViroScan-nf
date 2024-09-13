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
    for i in $listBashTable;do
        cat \$i >> ${output_name}.txt
    done
    """

}