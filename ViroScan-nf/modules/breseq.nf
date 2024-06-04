/*
Here are described all processes related to breseq
breseq is a computational pipeline specialized for the analysis of short-read re-sequencing data.
See https://barricklab.org/twiki/pub/Lab/ToolsBacterialGenomeResequencing/documentation/index.html
*/
 

// This process align reads against a fasta reference indexed
process breseq {
    label 'breseq' 
    tag "$sample" 
    publishDir "${params.outdir}/breseq_analysis", pattern: "*", mode: 'copy' // I want all sub-directories

    input:
        tuple val(sample), path(reads)
        path ref

    output:
        path ("*")

    script:


        """
            breseq -r ${ref} ${params.breseq_options} -j ${task.cpus} ${reads} -o ${sample} 2> ${sample}_breseq.log
        """

}