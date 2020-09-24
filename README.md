# callSSDSpeaks Pipeline
## Peak calling pipeline for SSDS data

This nextflow pipeline is a simple workflow to call peaks in a standardized way from single-stranded DNA sequencing (SSDS; Khil et al. Genome Res. 2012) experiments. The pipeline can also build a peak calling saturation curve to estimate the value of deeper sequencing. 

### Requirements: 
Nextflow (20.01.0+)

### Recommended:
Anaconda / miniconda 

### Conda environment: 
All dependencies can be installed using the included conda environment (accessoryFiles/conda/environment.yml). Although nextflow can take a conda env file as input, several of the packages will not work with the long path names used by nextflow. Instead, I recommend building the environment first, then passing the built environment in the nextflow config file.  
  
`conda env create --file accessoryFiles/conda/environment.yml`  
  
The path to the callSSDSHS conda env must be added in the configuration file (accessoryFiles/conf/config.nf).If you have an environment variable named $CONDA_ENVS pointing to your conda env folder, then config.nf can remain unchanged. 

### Alternative dependencies: 
If you are not using conda, you will need:  
  
BEDTools (2.20.0+)  
MACS (2.1.2+)  
R (3.2+)  
R-bioconductor: rtracklayer module  
R-bioconductor: shortread module  
