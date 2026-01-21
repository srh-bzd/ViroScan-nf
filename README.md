# ViroScan-nf  

![Nextflow](https://img.shields.io/badge/Nextflow-%3E%3D22.04.0-brightgreen)
![Docker](https://img.shields.io/badge/Docker-supported-blue)
![Singularity](https://img.shields.io/badge/Singularity-supported-blue)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**ViroScan-nf** is a Nextflow pipeline designed to separate host and viral reads from sequencing data, identify viral mutations, and compute viral alignment and coverage metrics.

The pipeline combines host read filtering, viral variant calling, and summary metric generation in a fully reproducible workflow.

## Table of Contents

   * [Foreword](#foreword)
   * [Installation](#installation)
      * [ViroScan-nf](#viroscan-nf)
      * [Nextflow](#nextflow)
      * [Container platform](#container-platform)
   * [Usage](#usage)
   * [Parameters](#parameters)
   * [Outputs](#outputs)
   * [Usage](#usage)
   * [Uninstall](#uninstall)
   * [Contributing](#contributing)
   * [Report bugs and issues](#report-bugs-and-issues)
   * [Acknowledgement](#acknowledgement)

## Foreword

ViroScan-nf is an automated pipeline that:
- Filters out host reads by aligning sequencing reads against a host reference genome using Bowtie2
- Retains unmapped reads and uses them as candidate viral reads
- Aligns viral reads to a viral reference genome using breseq
- Identifies viral mutations
- Computes viral alignment and coverage metrics directly from breseq outputs

## Installation

**Requirements**
  * [Nextflow](https://www.nextflow.io/) ≥ 22.04.0
  * [Docker](https://www.docker.com) or [Singularity](https://sylabs.io/singularity/) 
  * [Java](https://www.java.com/en/) ≥ 11

**ViroScan-nf**

```bash
# clone the workflow repository
git clone https://github.com/srh-bzd/ViroScan-nf.git

# Move in it
cd ViroScan-nf
```

**Nextflow** 

  * Using conda 

      ```bash
      conda create -n nextflow
      conda activate nextflow
      conda install nextflow
      ```

  * Manual installation

      ```bash
      # Make sure 11 or later is installed on your computer by using the command:
      java -version
      
      # Install Nextflow by entering this command in your terminal(it creates a file nextflow in the current dir):
      curl -s https://get.nextflow.io | bash 
      
      # Add Nextflow binary to your user's PATH:
      mv nextflow ~/bin/
      # OR system-wide installation:
      # sudo mv nextflow /usr/local/bin
      ```

**Container platform**

You must use Docker or Singularity.
- Docker: https://docs.docker.com/desktop/
- Singularity: https://docs.sylabs.io/guides/latest/admin-guide/installation.html

## Usage

Display available options:
```bash
nextflow run main.nf --help
```

Before running the workflow, make sure that the Python script used for generating viral metrics is executable:

```bash
chmod +x bin/write_viral_table.py
```

Run the pipeline using Docker:
```bash
nextflow run main.nf \
    -profile docker,local \
    --reads 'data/*R{1,2}.fq.gz' \
    --host_genome host.fasta \
    --viral_genome virus.gbk
```

Available profiles:
- `docker`
- `singularity`
- `local`
- `ifb`

Test the workflow:
```bash
nextflow run main.nf -profile local,docker,test 
```

## Parameters

**Mandatory parameters**

| Parameter        | Description                            |
| ---------------- | -------------------------------------- |
| `--reads`        | Input reads (supports `*R{1,2}.fq.gz`) |
| `--host_genome`  | Host reference genome (FASTA)          |
| `--viral_genome` | Viral genome (FASTA or GenBank)        |
| `--outdir`       | Output directory                       |

**Optional parameters**

| Parameter             | Default | Description                                         |
| --------------------- | ------- | --------------------------------------------------- |
| `--paired_end`        | true    | Paired-end or single-end reads                      |
| `--host_genome_index` | null    | Prefix of an existing Bowtie2 index (skip indexing) |
| `--run_fastp`         | true    | Enable read trimming                                |
| `--fastp_options`     | ""      | Additional fastp options                            |
| `--bowtie2_options`   | ""      | Additional Bowtie2 options                          |
| `--breseq_options`    | ""      | Additional breseq options                           |
| `--table_threshold`   | 5       | Minimum % viral alignment to report                 |
| `--help`              | false   | Display help message                                |

## Outputs

The main results are written to the directory specified by `--outdir`.

```bash
results/
├── 01.cleaned_reads
│   ├── log
│   │   └── sample_name_fastp.json
│   ├── sample_name_R1.fastq.gz
│   └── sample_name_R2.fastq.gz
├── 02.indexed_ref
├── 03.aligned_reads
│   ├── host
│   │   ├── bam
│   │   │   └── sample_name.bam
│   │   ├── sample_name_matched.fq.gz
│   │   ├── sample_name_matched_R1.fq.gz
│   │   └── sample_name_matched_R2.fq.gz
│   └── log
│       └── sample_name_bowtie2.log
├── 04.unmapped_reads
│   ├── host
│   │   ├── sample_name_unmatched.fq.gz
│   │   ├── sample_name_unmatched_R1.fq.gz
│   │   └── sample_name_unmatched_R2.fq.gz
│   └── viral
│       ├── sample_name_unmatched.fq.unmatched.fastq
│       ├── sample_name_unmatched_R1.fq.unmatched.fastq
│       └── sample_name_unmatched_R2.fq.unmatched.fastq
├── 05.called_variants
│   └── sample_name
│       ├── data
│       └── output
└── reports
    ├── multiqc_report.html
    └── viral_alignment_metrics.txt
```

**Viral metrics table**

Generated from `breseq summary.json`.
| Column                    | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| **Sample_ID**             | Name of the sample being analyzed                            |
| **Viral_genome**          | Viral reference genome ID used for alignment                 |
| **Num_reads**             | Total number of input sequencing reads                       |
| **Num_reads_aligned**     | Number of reads that aligned to the viral genome             |
| **Percent_reads_aligned** | Percentage of reads aligned to the virus                     |
| **Avg_coverage**          | Average sequencing coverage across the viral genome          |
| **Percent_coverage**      | Approximate percentage of the genome covered by reads        |
| **Num_bases_mapped**      | Total number of bases mapped to the viral genome             |
| **Num_genes**             | Number of viral genes detected                               |
| **Num_features**          | Number of genomic features detected                          |
| **Coverage_variance**     | Variability of coverage along the viral genome               |


## Uninstall

No installation is required.
To uninstall, simply delete the repository directory.

## Contributing

Contributions are welcome. 
See [Contributing guidelines](https://github.com/srh-bzd/ViroScan-nf/blob/main/CONTRIBUTING.md)

## Report bugs and issues

Please open an issue on GitHub:
https://github.com/srh-bzd/ViroScan-nf/issues

## Acknowledgement

Jacques Dainat (@Juke34)  
Based on the **BiTeN template**: https://github.com/Juke34/BiTeN