#! /usr/bin/env nextflow
nextflow.enable.dsl=2

// Import
import static groovy.io.FileType.FILES
import java.nio.file.*

//*************************************************
// STEP 0 - parameters
//*************************************************

/*
 * Default pipeline parameters. They can be overriden on the command line eg.
 * given `params.foo` specify on the run command line `--foo some_value`.
 * See https://www.nextflow.io/docs/latest/config.html#configuration
 */

// Input/output params
params.help = false
params.reads = "/path/to/reads/foder/"
params.genome = "/path/to/genome.fa"
params.outdir = "results"
params.reads_extension = ".fastq.gz" // Extension used to detect reads in folder
params.paired_reads_pattern = "{1,2}"


// Read feature params
params.single_end = true // Boolean to see if we have a single end or paired end data set
params.stranded = false // Boolean to see if we have a single or stranded data set

// Step params
params.run_fastp = true // Boolean to decide to launch trimming

// Extra parameter provided by the user to the tool
params.bowtie2_options = ''
params.breseq_options = ''
params.table_threshold = 5 // This is a percent

//*************************************************
// STEP 1 - LOG INFO
//*************************************************

// ------------ First an header printed in all cases -----------------
log.info header()

// ------------ A help printed only when --help is called -----------------

if (params.help) { exit 0, helpMSG() }

// Help Message
def helpMSG() {
    log.info """
    ********* HELP *********

        Usage example:
    nextflow run -profile docker main.nf --genome test/hpv16.fa --reads test

    --help                      prints the help section

        Input Reads:
    --reads                     path to the directory containing the reads 
    --pattern_reads             pattern to match the read files. In the case of single end data it would looks like: "*.fastq.gz"
                                                                 In the case of paired end data it would looks like: "*_{R1,R2}_001.fastq.gz" or "*_{1,2}.fastq.gz"        
    --single_end                Boolean to inform if we have a single end or paired end data. (default: ${params.single_end})
    --stranded                  Boolean to inform if we have a single or stranded data. (default: ${params.stranded})

        Input Genome:
    --genome                    path to the genome file in fasta format

        Alignment
    --bowtie2_options           Parameter to tune the bowtie2 aligner behaviour.  (default: ${params.bowtie2_options})
    """
}

// ------------ When --help is called we never go further. If no help asked, let's report to the user the parameters taken into account by the pipeline -----------------

log.info """
General Parameters
    genome                     : ${params.genome}
    reads                      : ${params.reads}
    paired_reads_pattern       : ${params.paired_reads_pattern}
    single_end                 : ${params.single_end}
    outdir                     : ${params.outdir}
  
Alignment Parameters
 bowtie2 parameters
     bowtie2_options            : ${params.bowtie2_options}
 
 """

//*************************************************
// STEP 2A - Include needed modules
//*************************************************

include { bowtie2_index; bowtie2 } from "$baseDir/modules/bowtie2.nf"
include { breseq } from "$baseDir/modules/breseq.nf"
include { fastp } from "$baseDir/modules/fastp.nf"
include { write_output_tables } from "$baseDir/modules/python.nf"
include { concat_tables as concat_tables1; concat_tables as concat_tables2} from "$baseDir/modules/bash.nf"
// When using the same process several times like here with  fastqc you must provide a specific name
// by call using this structure "fastqc as fastqc_raw" where the process fastqc will be available here with the name fastqc_raw
include { fastqc as fastqc_raw; fastqc as fastqc_ali } from "$baseDir/modules/fastqc.nf"
include { samtools_sam2bam; samtools_sort  } from "$baseDir/modules/samtools.nf"

//*************************************************
// STEP 2B - Include needed subworkflows if outside of this file. See Sub-workflow paragraph
//*************************************************

//*************************************************
// STEP 3 - Deal with parameters
//*************************************************

// check profile
if (
    workflow.profile.contains('singularity') ||
    workflow.profile.contains('docker')
  ) { "executer selected" }
else { exit 1, "No executer selected: -profile docker/singularity"}

// check input (file or folder?)
def list_files = []
def pattern_reads
def fromFilePairs_input
def path_reads = params.reads 

// in case of folder provided, add a trailing slash if missing
File input_reads = new File(path_reads)
if(input_reads.exists()){
    if ( input_reads.isDirectory()) {
        if (! input_reads.name.endsWith("/")) {
            path_reads = "${path_reads}" + "/"
        }
    }
}

if (params.single_end) {
    pattern_reads = "${params.reads_extension}"
    fromFilePairs_input = "${path_reads}*${params.reads_extension}"
} else {
    pattern_reads = "${params.paired_reads_pattern}${params.reads_extension}"
    fromFilePairs_input = "${path_reads}*${params.paired_reads_pattern}${params.reads_extension}"
}

if(input_reads.exists()){
    if ( input_reads.isDirectory()) {
        log.info "The input ${path_reads} is a folder!\n"
        input_reads.eachFileRecurse(FILES){
            if (it.name =~ ~/${pattern_reads}/){
                list_files.add(it)
            }
        }
        samples_number = list_files.size()
        log.info "${samples_number} files in ${path_reads} with pattern ${pattern_reads}"
    }
    else {
        log.info "The input ${path_reads} is a file!\n"
        pattern_reads = "${path_reads}"
    }
} else {
    exit 1, "The input ${path_reads} does not exists!\n"
}

//*************************************************
// Main Workflow - 
//*************************************************
// It can connect several sub workflows
// Here we have only one called ALIGN. If we do not want any subworkflow at all you will have to remove the "ALIGN(reads,genome)" line
// and then move all the code from ALIGN here excepted:
//workflow ALIGN {
//
//    take:
//        reads
//        genome
//
//    main:
//}
//*************************************************


workflow {

    main:
        Channel.fromFilePairs(fromFilePairs_input, size: params.single_end ? 1 : 2, checkIfExists: true)
            .ifEmpty { exit 1, "Cannot find reads matching ${path_reads}!\n" }
            .set {reads}
        Channel.fromPath(params.genome, checkIfExists: true)
            .ifEmpty { exit 1, "Cannot find genome matching ${params.genome}!\n" }
            .set {genome}
        ALIGN(reads,genome)
}

//*************************************************
// Sub-Workflow
//*************************************************
// Sub-Workflow align 
// For clarity you may decide to move this part into a folder name subworflows in a file called e.g. align.nf
// To make it accessible from here you will have to import the subworklow as follow:
// include { ALIGN } from "${baseDir}/subworkflows/ALIGN.nf"
// A subworkflow behaves like a process, in the case your main workflow needs to get access to a result 
// emited by the sub-subworklow, you must use the emit: statement at the end of the sub-subworklow.
//*************************************************

workflow ALIGN {

    take:
        reads
        genome

    main:

        // ------------------- FASTP -----------------
        if (params.run_fastp){
            fastp(reads) // trimming
            fastp.out[0].set{tuple_sample_fastq_after_trimming}
        } else {
            tuple_sample_fastq_after_trimming = reads
        }
    

        // ------------------- BOWTIE2 -----------------
        bowtie2_index(genome) // index
        // Filter out - we remove the reads that align to the reference genomes
        bowtie2(tuple_sample_fastq_after_trimming, bowtie2_index.out.collect(), genome.collect()) // align

        // ------------------- BRESEQ -----------------
        // Filter in - we align and keep the reads that align to the reference genomes
        breseq(bowtie2.out.tuple_sample_fastq, genome.collect())

        // ------------------- METRICS -----------------
        // create the metrics tables
        write_output_tables(breseq.out.tuple_breseq_sample_json)
        // concat the metric_percent tables
        concat_tables1(write_output_tables.out.metric_percents.collect(), "metric_percents_all")
        // concat the metric_counts tables
        concat_tables2(write_output_tables.out.metric_counts.collect(), "metric_counts_all")
        // breseq.out.tuple_breseq_sample_json.toList().map{[it]}.view()

        // ------------------- SAMTOOLS -----------------
        //samtools_sam2bam(bowtie2.out.tuple_sample_sam)
        // sort
        //samtools_sort(samtools_sam2bam.out.tuple_sample_bam)
        
}


//*************************************************
// extra functions
//*************************************************
def header(){
    // Log colors ANSI codes
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";

    return """
    -${c_dim}--------------------------------------------------${c_reset}-
    ${c_blue}.-./`) ${c_white}.-------.    ${c_red} ______${c_reset}
    ${c_blue}\\ .-.')${c_white}|  _ _   \\  ${c_red} |    _ `''.${c_reset}     French National   
    ${c_blue}/ `-' \\${c_white}| ( ' )  |  ${c_red} | _ | ) _  \\${c_reset}    
    ${c_blue} `-'`\"`${c_white}|(_ o _) /  ${c_red} |( ''_'  ) |${c_reset}    Research Institute for    
    ${c_blue} .---. ${c_white}| (_,_).' __ ${c_red}| . (_) `. |${c_reset}
    ${c_blue} |   | ${c_white}|  |\\ \\  |  |${c_red}|(_    ._) '${c_reset}    Sustainable Development
    ${c_blue} |   | ${c_white}|  | \\ `'   /${c_red}|  (_.\\.' /${c_reset}
    ${c_blue} |   | ${c_white}|  |  \\    / ${c_red}|       .'${c_reset}
    ${c_blue} '---' ${c_white}''-'   `'-'  ${c_red}'-----'`${c_reset}
    ${c_purple} ${workflow.manifest.name} - Filter-out Filter-in in Nextflow - v${workflow.manifest.version}${c_reset}
    -${c_dim}--------------------------------------------------${c_reset}-
    """.stripIndent()
}

//*************************************************
// Information to report at the end of the pipeline
//*************************************************

workflow.onComplete {
    log.info ( workflow.success ? "\n${workflow.manifest.name} pipeline complete!\n" : "Oops .. something went wrong\n" )

    log.info """
    ${workflow.manifest.name} Pipeline execution summary
    --------------------------------------
    Completed at : ${workflow.complete}
    UUID         : ${workflow.sessionId}
    Duration     : ${workflow.duration}
    Success      : ${workflow.success}
    Exit Status  : ${workflow.exitStatus}
    Error report : ${workflow.errorReport ?: '-'}
    """

    
    if (workflow.success) {
        log.info """
        Results are available in the folder: ${params.outdir}
        """
        // remove folder work
        if (params.remove_workdir) {
            def work = Paths.get("${workflow.projectDir}/work")
            if (Files.exists(work)) {
                log.info "        Removing ${work} folder"
                Files.walk(work)
                    .sorted(Comparator.reverseOrder())
                    .map(Path::toFile)
                    .forEach(File::delete)
            }
        }
    }
}

