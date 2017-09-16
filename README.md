# Running Ariba
This workflow can be run with either bam or fastq files as inputs and specifiy either a pre-formatted local Ariba database or get a fresh database 'on the fly'.

## Usage
```
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
```

## With bam files
```
nextflow run -with-singularity /path/to/singularity.img --ariba_db_dir /path/to/ariba/resistance/db --input_dir /path/to/input/dir --output_dir /path/to/ouput/dir --bam_pattern "*.bam" ariba.nf
```

Test example specifying a **local ariba database**
```
nextflow run -with-singularity /docker/singularity/ariba-2017-08-14-25c888e807cd.img --ariba_db_dir local_ariba_db  --input_dir $PWD --output_dir $PWD/ariba_ouput --bam_pattern "bams/*.bam" ariba.nf
```

## With fastq files
```
nextflow run -with-singularity /path/to/singularity.img --ariba_db_dir /path/to/ariba/resistance/db --input_dir /path/to/input/dir --output_dir /path/to/ouput/dir --fastq_pattern "*.R{1,2}.fastq.gz" ariba.nf
```

Test example specifying to **get an up to date version of the card database**
```
nextflow run -with-singularity /docker/singularity/sangerpathogens_ariba-2017-08-14-eac72eee2a51.img --get_database card  --input_dir $PWD --output_dir $PWD/ariba_ouput --fastq_pattern "fastqs/*.{R1,R2}.fastq.gz" ariba.nf
```

## Building Docker image

```
docker build -t ariba -f ariba.Dockerfile .
```

If you need to specify proxies use this command

```
docker build -t ariba -f ariba.Dockerfile --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy --build-arg HTTP_PROXY=$http_proxy --build-arg HTTPS_PROXY=$http_proxy .
```
