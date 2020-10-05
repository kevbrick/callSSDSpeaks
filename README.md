# callSSDSpeaks Pipeline
## Peak calling pipeline for SSDS data

This nextflow pipeline is a simple workflow to call peaks in a standardized way from single-stranded DNA sequencing (SSDS; Khil et al. Genome Res. 2012) experiments. The pipeline can also build a peak calling saturation curve to estimate the value of deeper sequencing. 

### Requirements: 
Nextflow (20.07.0+)

### How to run:
nextflow run -c config.nf -profile singularity callSSDSpeaks.nf --tbed ssds.bed --cbed ctrl.bed --genome mm10 --name test 

### Recommended:
Singularity / Docker  
The dependencies for this pipeline are stored as a docker container that can be used by either Singularity (Tested) or Docker (Untested). 

### Alternative 1:
Anaconda / miniconda 

### Conda environment: 
All dependencies can be installed using the included conda environment (accessoryFiles/conda/environment.yml). Although nextflow can take a conda env file as input, several of the packages will not work with the long path names used by nextflow. Instead, I recommend building the environment first, then passing the built environment in the nextflow config file.  
  
`conda env create --file accessoryFiles/conda/environment.yml`  
  
The path to the callSSDSHS conda env must be added in the configuration file (accessoryFiles/conf/config.nf).If you have an environment variable named $CONDA_ENVS pointing to your conda env folder, then config.nf can remain unchanged. 

### Alternative 2: (not recommended): 
BEDTools (2.20.0+)  
MACS (2.1.2+)  
R (3.6)  
R: ggplot2 package  
R: gridextra package  
R-bioconductor: shortread package   
Perl module: Getopt::Long  
Perl module: Statistics::Descriptive  
Perl module: Math::Round  
Perl module: List::Util  

### Global variables required:
$NXF_GENOMES   : Path to folder containing reference genomes for alignment
$SLURM_JOBID   : Specifies the temporary subfolder to use  (see Temp folder requirements below)

### NXF_GENOMES Folder structure
Each reference genome should be contained in a separate folder (i.e. $NXF_GENOMES/mm10). The sub-structure within this folder should be as follows:  
  
$NXF_GENOMES/\<genome\>/genome.fa                : Genome fasta file   
$NXF_GENOMES/\<genome\>/genome.fa.fai            : Index of genome fasta file (samtools faidx)  
  
### Temp folder requirements
The pipeline requires a high-level temporary folder called /lscratch. On a SLURM-based HPC, each job is assigned a global id ($SLURM_JOBID) and this is appended to the temp folder name for each process. This can be modified in the config.nf file. Thus, there is a requirement for :  
  
/lscratch folder for temporary files  
SLURM_JOBID global variable for each HPC job.  
  
### Genomes support
For any organism, there are three requirements:  
1. genome FASTA file
2. genome FASTA index
3. Genome blacklist BED file (in accessoryFiles/blacklist)  
   Blacklist files provided for mouse mm10 and human hg38 genomes. 
   A placeholder blacklist BED file must be used if blacklisting is not required or if blacklisted regions are unknown.
