# QuasiFlow

[![](https://img.shields.io/badge/nextflow-21.04.1-yellowgreen)](https://www.nextflow.io)
[![](https://img.shields.io/badge/uses-singularity-brightgreen)](https://docs.sylabs.io/guides/3.0/user-guide/installation.html)
[![](https://img.shields.io/badge/uses-docker-orange)](https://docs.docker.com/get-docker)
[![](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

[![Twitter Follow](https://img.shields.io/twitter/follow/alfred_ug.svg?style=social)](https://twitter.com/alfred_ug) 

A Nextflow Pipeline for Analysis of NGS-based HIV Drug Resistance Data

## Installation

QuasiFlow requires that you have Nextflow (version 21.04.3 or higher). Install [Nextflow](https://nf-co.re/usage/installation) and [Docker](https://docs.docker.com/engine/installation/) or [Singularity](https://docs.sylabs.io/guides/3.0/user-guide/installation.html) to run the pipeline. 

####  Use Nextflow to pull the pipeline. 

In this case, all dependencies will be pulled automatically. 

```bash
nextflow pull AlfredUg/QuasiFlow
nextflow run QuasiFlow --help
```

##### Native installation

Alternatively, you can first install the dependancies.

Below is the list of tools that are used in the QuasiFlow pipeline. These tools are readliy available and may be installed using `conda` or `pip`.

+ [fastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc)
+ [MultiQC](https://multiqc.info/)
+ [Trim-galore](https://github.com/FelixKrueger/TrimGalore)
+ [Quasitools](https://phac-nml.github.io/quasitools/)
+ [Sierra-local](https://github.com/PoonLab/sierra-local)
+ R packages (Jsonlite, plyr, dplyr, flexdashboard, rmarkdown, knitr), all available in [CRAN](https://cran.r-project.org/)

Clone the QuasiFlow repository and test the help

```bash
git clone https://github.com/AlfredUg/QuasiFlow.git
cd QuasiFlow
nextflow run quasiflow.nf --help
```

## Usage

Below is a basic command to run QuasiFlow. More parameters can be specified either in the `nextflow.config` file or simply given as commandline arguments.

```
nextflow run quasiflow.nf --reads path/to/reads -profile base
```

Run QuasiFlow on a test dataset. 

```
git clone https://github.com/AlfredUg/QuasiFlow.git
cd QuasiFlow

nextflow run quasiflow.nf --min_freq 0.2 --min_dp 1000
```

As the pipeline runs, parameters information and analysis progress will be printed on screen, an example of which is shown below.

```
N E X T F L O W  ~  version 21.04.1
Launching `quasiflow.nf` [modest_shannon] - revision: efb4fdde33
============================================================
 AlfredUg/QuasiFlow   ~  version 1.0.1
============================================================
Run Name       : modest_shannon
Reads          : /path/to/QuasiFlow/test_data/*{1,2}.fastq
Output directory: /path/to/QuasiFlow/results
Reporting threshold: 1
Consensus percentage: 20
Minimum read quality: 30
Length cut off : 100
Score cutoff   : 30
Minimum variant quality: 30
Minimum depth  : 1000
Minimum allele count: 5
Minimum mutation frequency: 0.2
Report template: /path/to/QuasiFlow/assets/hivdr.Rmd
Current home   : /path/to/user/home
Current user   : user
Current path   : /path/to/QuasiFlow
Script dir     : /path/to/QuasiFlow
Config Profile : standard
=========================================
executor >  local (9)
[13/8b73da] process > runfastQC (DRR030219)      [100%] 2 of 2 ✔
[76/e83952] process > runMultiQC                 [100%] 1 of 1 ✔
[b8/d89a64] process > runHydra (DRR030219)       [100%] 2 of 2 ✔
[15/decfee] process > runSierralocal (DRR030219) [100%] 2 of 2 ✔
[5f/c5d871] process > renderReport (DRR030219)   [100%] 2 of 2 ✔
WARN: Task runtime metrics are not reported when using macOS without a container engine
Completed at: 25-Jun-2022 19:57:26
Duration    : 4m 18s
CPU hours   : 0.1
Succeeded   : 9
```

By default the outputs are saved in the `results` directory with a structure shown below.

```
results
|
|   consensus*.fasta
|   consensus*.json
|   dr_report*.csv
|   filtered*.fastq
|   mutation_report*.aavf
|   hivdr*.html
|
|____qcresults-raw-reads
|   |   raw_reads_multiqc_report.html
|   |
│   │___DRR030218_fastqc
|   |   |   DRR030218_1_fastqc.zip
|   |   |   DRR030218_2_fastqc.zip
|   |   
│   │___DRR030219_fastqc
|       |   DRR030219_1_fastqc.zip
|       |   DRR030219_2_fastqc.zip
|           
└───pipeline_info
|   │   QuasiFlow_DAG.html
|   |   QuasiFlow_report.html
|   │   QuasiFlow_timeline.html
|   │   QuasiFlow_trace.txt
```

#### Quality control

* `raw_reads_multiqc_report.html`: Aggregated quality control data and visualisations - one file for entire dataset

#### Variants and drug resistance outputs

* `consensus*.fasta`: `FASTA` files of consensus sequences - one per sample
* `consensus*.json`: `JSON` files of detailed HIV drug resistance analysis - one per sample
* `dr_report*.csv`: `CSV` files of drug resistance mutations at different mutational frequencies - one per sample
* `filtered*.fastq`: `FASTQ` files of drug resistance mutations at different mutational frequencies - one per sample
* `mutation_report*.aavf`: `AAVF` files of amino acid variant calls - one per sample
* `hivdr*.html`: `HTML` Final drug resistance report - one per sample

Examples of drug resistance reports are available at the links below.

+ [Example 1](https://alfredug.github.io/QuasiFlow/hivdr_DRR030225.html)
+ [Example 2](https://alfredug.github.io/QuasiFlow/hivdr_DRR030224.html)

#### Pipeline information output

* `QuasiFlow_DAG.html`: 
* `QuasiFlow_report.html`: 
* `QuasiFlow_timeline.html`: 
* `QuasiFlow_trace.txt`: 

## Parameters

### HyDRA parameters

Mandatory parameters

* `--reads`: Path to input data (must be surrounded with quotes)

Optional parameters

* `--reporting_threshold`: Minimum mutation frequency percent to report.

* `--consensus_pct`: Minimum percentage a base needs to be incorporated into the consensus sequence.

* `--min_read_qual`: Minimum quality for a position in a read to be masked.	     

* `length_cutoff`: Reads which fall short of the specified length will be filtered out.

* `score_cutoff`: Reads that have a median or mean quality score (depending on the score type specified) less than the score cutoff value will be filtered out.

* `--min_variant_qual`: Minimum quality for variant to be considered later on in the pipeline.

* `--min_dp`: Minimum required read depth for variant to be considered later on in the pipeline.

* `--min_ac`: The minimum required allele count for variant to be considered later on in the pipeline

* `--min_freq`: The minimum required frequency for mutation to be considered in drug resistance report.


### Sierralocal parameters

Optional parameters

* `--xml`: Path to HIVdb ASI2 XML.

* `--apobec-tsv`: Path to tab-delimited (tsv) HIVdb APOBEC DRM file.

* `--comments-tsv`: Path to tab-delimited (tsv) HIVdb comments file.


### Output parameters

Optional parameters

* `--outdir`: Path to directory where results will be saved 

### Profiles

Quasiflow can be run under different computing environments, simply choose an appropriate profile via the `-profile` argument. Could take any of the following `-profile base, singularity, docker`. Custom profiles can be added to the `conf` directory using any of the available profiles as a template.

## Troubleshooting

Kindly report any issues [here](https://github.com/AlfredUg/QuasiFlow/issues).

## License

QuasiFlow is licensed under GNU GPL v3.


## Citation

**This work is currently under peer review. A formal citation will be availed in due course.**
