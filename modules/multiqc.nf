/*
 * Aggregate QC and alignment reports using MultiQC.
 * MultiQC: https://multiqc.info/
 */

process MULTIQC {
    label 'multiqc' 
    publishDir "$params.outdir", mode: 'copy'

    input:
    path '*'

    output:
    path 'multiqc_report.html'

    script:
    """
        multiqc .
    """
}