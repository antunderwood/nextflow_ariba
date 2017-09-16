#!/usr/bin/env nextflow
/*

========================================================================================
                          Ariba Pipeline
========================================================================================
 Mykrobe predictor
 #### Authors
 Martin Hunt @martibartfast
 Anthony Underwood @bioinformant <anthony.underwood@phe.gov.uk>
----------------------------------------------------------------------------------------
*/

// Pipeline version
version = '1.0'
//  print help if required
def helpMessage() {
    log.info"""
    =========================================
     Ariba Pipeline v${version}
    =========================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run -with-singularity/-with-docker [options] ariba.nf
    Mandatory arguments:
      --input_dir      Path to input dir "must be surrounded by quotes"
      --output_dir     Path to output dir "must be surrounded by quotes"
    Options:
    One of these patterns to match input files must be specified
      --bam_pattern    The regular expression that will match bam files e.g '*.bam'
      --fastq_pattern  The regular expression that will match fastq files e.g '*_{1,2}.fastq.gz'
    One of these parameters to specify how the AMR database can be found/created
      --ariba_db_dir   Path to dir containing ariba resitance database "must be surrounded by quotes"
      --get_database   Specify a valid database from argannot, card, megares, plasmidfinder, resfinder, srst2_argannot, vfdb_core, vfdb_full, virulencefinder
   """.stripIndent()
}

params.help = false
// Show help message
if (params.help){
    helpMessage()
    exit 0
}

/***************** Setup inputs and channels ************************/
// Defaults for configurable variables
params.input_dir = false
params.output_dir = false
params.ariba_db_dir = false
params.get_database = false
params.fastq_pattern = false
params.bam_pattern = false

def check_mandatory_parameter(params, parameter_name){
   if ( !params[parameter_name]){
      error "You must specifiy a " + parameter_name
   } else {
      variable = params[parameter_name]
      return variable
   }
}

def check_optional_parameters(params, parameter_names){
  if (parameter_names.collect{element -> params[element]}.every{element -> element == false}){
    error "You must specifiy at least one of these options: " + parameter_names.join(', ')
  }
}
// set up input_dir
input_dir = file(check_mandatory_parameter(params, "input_dir"))
// set up output directory
output_dir = file(check_mandatory_parameter(params, "output_dir"))
// set up ariba database
check_optional_parameters(params, ['ariba_db_dir', 'get_database'])

// make database if required
if (params.get_database) {
  database = params.get_database
  process get_database{
    input:
    database

    output:
    file("${database}.out") into ariba_db_dir

    script:
    """
    ariba getref ${database} ${database}
    ariba prepareref -f ${database}.fa -m ${database}.tsv ${database}.out
    """
  }
} else if (params.ariba_db_dir){
  ariba_db_dir = file(params.ariba_db_dir)
}

//  check a pattern has been specified
check_optional_parameters(params, ['bam_pattern', 'fastq_pattern'])
// set up read_pair channel if fastqs specified
if ( params.fastq_pattern) {
    /*
     * Creates the `read_pairs` channel that emits for each read-pair a tuple containing
     * three elements: the pair ID, the first read-pair file and the second read-pair file
     */
    fastqs = params.input_dir + '/' + params.fastq_pattern
    Channel
      .fromFilePairs( fastqs )
      .ifEmpty { error "Cannot find any reads matching: ${fastqs}" }
      .set { read_pairs }
}

// create read_pairs channel via bedtools if bams specified
if (params.bam_pattern) {
  bams = params.input_dir + '/' + params.bam_pattern
  Channel
    .fromPath( bams )
    .ifEmpty { error "Cannot find any bam files matching: ${bams}" }
    .set {bam_files}

  process bam_to_paired_fastqs {
    input:
    file(bam_file) from bam_files

    output:
    set val(suffix), file("*.fastq") into read_pairs

    script:
    suffix = bam_file.baseName
    """
    bedtools bamtofastq -i ${bam_file} -fq ${suffix}.R1.fastq -fq2 ${suffix}.R2.fastq
    """
  }
}

 process run_ariba {
   publishDir output_dir, mode: 'copy'

   input:
   set pair_id, file(file_pair)  from read_pairs
   file("ariba_db") from ariba_db_dir

   output:
   set pair_id, file("${pair_id}.ariba")
   file "${pair_id}.report.tsv" into summary_channel

   """
   ariba run ariba_db ${file_pair[0]} ${file_pair[1]} ${pair_id}.ariba
   cp ${pair_id}.ariba/report.tsv ${pair_id}.report.tsv
   """
 }

process run_ariba_summary {
  publishDir output_dir, mode: 'copy'

  input:
  file summary_tsv from summary_channel.collect()

  output:
  file "ariba_summary.*"

  """
  ariba summary ariba_summary ${summary_tsv}
  """

}
