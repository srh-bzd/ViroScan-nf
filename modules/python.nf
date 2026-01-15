/*
 * Generate viral alignment metrics table from breseq output.
 * Script: custom Python script
 */

process VIRAL_METRICS_TABLE { 
    label 'python'
    tag "Reporting viral alignment metrics for $sample_id"

    input:
    path script
    tuple val(sample_id), path("${sample_id}/data/summary.json")

    output:
    path "*_viral_alignment_metrics.txt"

    script:
    """
    python ${script} ${sample_id} \\
                           ${sample_id}/data/summary.json \\
                           ${sample_id}_viral_alignment_metrics.txt \\
                           ${params.table_threshold}
    """
}
