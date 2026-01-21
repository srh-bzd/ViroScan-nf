#!/usr/bin/env nextflow
nextflow.enable.dsl=2


/*
 * Pipeline input parameters
 */
// Input / output params
params.reads = "$baseDir/test/*R{1,2}.f*q*"
params.host_genome = "$baseDir/test/hpv16.fasta"
params.host_genome_index = null
params.viral_genome = "$baseDir/test/hpv6-11.gbk"
params.outdir = "$baseDir/results"

// Read feature params
params.paired_end = true

// Step trimming
params.run_fastp = true

// Extra parameters provided by the user to the tools
params.fastp_options = ''
params.bowtie2_options = ''
params.breseq_options = ''
params.table_threshold = 5

// Help 
params.help = false


/*
 * Logging and help
 */
// Infos
log.info """\
         =======================================
         V I R O S C A N - N F   P I P E L I N E    
         =======================================
         Host genome     : ${params.host_genome}
         Viral genome    : ${params.viral_genome}
         Reads           : ${params.reads}
         Paired-end      : ${params.paired_end}
         Outdir directory: ${params.outdir}

         Run fastp       : ${params.run_fastp}
         Fastp options   : ${params.fastp_options}
         Bowtie2 options : ${params.bowtie2_options}
         Breseq options  : ${params.breseq_options}
         Table threshold : ${params.table_threshold}
         """
         .stripIndent(true)

if (params.help) { exit 0, helpMSG() }

// Help Message
def helpMSG() {
    log.info """
    ********* HELP *********

    Usage example:
        nextflow run main.nf \\
            -profile docker,local \\
            --reads test/'*R{1,2}.fq.gz' \\
            --host_genome test/hpv16.fasta \\
            --viral_genome test/hpv6-11.gbk

    Mandatory options:
        --reads                     Reads to analyse       
        --paired_end                Boolean: single-end or paired-end. (default: ${params.paired_end})
        --viral_genome              Path to viral genome (FASTA or Genbank)
        --host_genome               Path to host genome (FASTA)
        --host_genome_index         Path prefix to an existing Bowtie2 index (optional)
                                    If provided, index building is skipped
        --outdir                    Path to the output results directory. (default: ${params.outdir})

    Supplementary options:
        --run_fastp                 Run trimming with fastp. (default: ${params.run_fastp})
        --fastp_options             Additional options for fastp
        --bowtie2_options           Additional options for bowtie2
        --breseq_options            Additional options for breseq
        --table_threshold           Minimum viral alignment % to report. (default: ${params.table_threshold})
    """
    .stripIndent(true)
}


/*
 * Include pipeline modules
 */
include { FASTP_TRIMMING } from "$baseDir/modules/fastp.nf" 
include { MULTIQC } from "$baseDir/modules/multiqc.nf"
include { BOWTIE2_INDEX; BOWTIE2_ALIGN } from "$baseDir/modules/bowtie2.nf" 
include { SAMTOOLS_CONVERT_AND_SORT } from "$baseDir/modules/samtools.nf" 
include { BRESEQ_VARIANT_CALLING } from "$baseDir/modules/breseq.nf" 
include { VIRAL_METRICS_TABLE } from "$baseDir/modules/python.nf" 
include { CONCAT_VIRAL_METRICS_TABLES } from "$baseDir/modules/bash.nf" 


/*
 * Validate input files
 */
if (params.host_genome_index) {
    def bt2_files = [
        "${params.host_genome_index}.1.bt2",
        "${params.host_genome_index}.2.bt2",
        "${params.host_genome_index}.3.bt2",
        "${params.host_genome_index}.4.bt2"
    ]

    if (!bt2_files.every { file(it).exists() }) {
        error "Bowtie2 index not found or incomplete for prefix: ${params.host_genome_index}"
    }
} else {
    if (!file(params.host_genome).exists()) {
        error "Host genome file not found: ${params.host_genome}"
    }
}


if (!file(params.viral_genome).exists()) {
    error "Viral genome file not found: ${params.viral_genome}"
}

reads_files = file(params.reads).toList()
if (!reads_files) {
    error "No reads found matching: ${params.reads}"
}


/*
 * Workflow
 */
workflow {
     // --- Prepare reads channel ---
    reads_ch = Channel.fromFilePairs(params.reads, size: params.paired_end ? 2 : 1, checkIfExists: true)

    // --- Optional trimming ---
    if (params.run_fastp) {
        trimming_out = FASTP_TRIMMING(reads_ch)
        trimmed_reads_ch = trimming_out.trimmed_reads
        fastp_reports_ch = trimming_out.fastp_report
    } else {
        trimmed_reads_ch = reads_ch
        fastp_reports_ch = Channel.empty()
    }

    // --- Viral genome ---
    viral_genome_ch = Channel.value(file(params.viral_genome))

    // --- Host filtering ---
    if (params.host_genome_index) {
        index_ch = Channel.value(tuple(params.host_genome_index, file("${params.host_genome_index}*.bt2"))) 
    } else {
        host_genome_ch = Channel.value(file(params.host_genome))
        index_ch = BOWTIE2_INDEX(host_genome_ch)
    }
    alignment_out = BOWTIE2_ALIGN(index_ch, trimmed_reads_ch)

    // --- BAM conversion ---
    bam_out = SAMTOOLS_CONVERT_AND_SORT(alignment_out.sam_file)

    // --- MultiQC ---
    reports_ch = params.run_fastp ? fastp_reports_ch.mix(alignment_out.bowtie2_report) : alignment_out.bowtie2_report
    MULTIQC(reports_ch.collect())

    // --- Viral mutation calling ---
    variant_calling_out = BRESEQ_VARIANT_CALLING(viral_genome_ch, alignment_out.unmatched_reads)

    // --- Viral metrics ---
    metrics_out = VIRAL_METRICS_TABLE(file("$baseDir/bin/write_viral_table.py"), variant_calling_out.breseq_json_file)
    CONCAT_VIRAL_METRICS_TABLES(metrics_out.collect())
}


/*
 * Workflow completion handlers
 */
workflow.onComplete {
    log.info ( workflow.success ? "\n✓ Pipeline completed successfully!\n✓ Results available in: ${params.outdir}\n" : "\n✗ Pipeline failed. Check logs and intermediate files for details.\n" )
}