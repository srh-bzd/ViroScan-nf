/*
 * Concatenate viral alignment metrics tables for all samples into a single text file.
 */

process CONCAT_VIRAL_METRICS_TABLES { 
    publishDir "$params.outdir/reports", mode: 'copy'

    input:
    path txt_files

    output:
    path "viral_alignment_metrics.txt"

    script:
    """
        echo -e "Sample_ID\tViral_genome\tNum_reads\tNum_reads_aligned\tPercent_reads_aligned\tAvg_coverage\tPercent_coverage\tNum_bases_mapped\tNum_genes\tNum_features\tCoverage_variance" > viral_alignment_metrics.txt
        cat *_viral_alignment_metrics.txt >> viral_alignment_metrics.txt
    """
}
