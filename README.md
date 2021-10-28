# QuasiFlow
A Nextflow Pipeline for Analysis of NGS-based HIV Drug Resistance Data

## Dependencies

+ FastQC
+ MultiQC
+ Trim-galore
+ Quasitools
+ Sierra-local
+ R packages; ggplot2, jsonlite, knitr, rmarkdown, flexdashboard

## Testing the pipeline

### Natively

```
git clone https:https://github.com/AlfredUg/QuasiFlow.git
cd QuasiFlow
nextflow run testRmd.nf
```

### Using docker/singularity

```
git clone https:https://github.com/AlfredUg/QuasiFlow.git
cd QuasiFlow
nextflow run testRmd.nf -with-docker
nextflow run testRmd.nf -with-singularity
```

# TO DO

The parts in bold text are due before circulation of manuscript to other co-authors, we shall look into other parts as we go along.

+ **Sanitize the config file, add docker/singularity configuration, job schedulers, comprehensive paramater list** - Alfred
+ **Fix the parsing of files to Rmd as parameters in nextflow** - Alfred and Ibra **FIXED**
+ **Display comments for each drug class/ARV from json file** - Ibra
+ **Add version of HIVDB used to html report** - Alfred
+ Convert html report to pdf
+ Provide a report of aggregation of results in case of batch analysis
+ Combine individual reports into single html file, 
