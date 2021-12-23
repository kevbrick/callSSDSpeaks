# callSSDSpeaks Pipeline
## Peak calling pipeline for SSDS data

This nextflow pipeline is a simple workflow to call peaks in a standardized way from single-stranded DNA sequencing (SSDS; Khil et al. Genome Res. 2012) experiments. The pipeline can also build a peak calling saturation curve to estimate the value of deeper sequencing. 

### Requirements: 
Nextflow (20.07.0+)

NXF_GENOMES environment variable:
This should point to a folder that contains a nameed subfolder for the reference genome of interest (i.e. $NXF_GENOMES/mm10). For each reference genome, this folder must contain the reference genome fasta file named **genome.fa** and a fasta index named **genome.fa.fai**. 
```
>export NXF_GENOMES='/data/$USER/genomes'
>ls $NXF_GENOMES
hg38  mm10
>ls $NXF_GENOMES/mm10
genome.fa.fai
```
OR 
a genome index file (genome.fa.fai; specify with: 
```--idx <<full path to genome.fa.fai>>```

#### Temp folder requirements
The pipeline requires a high-level temporary folder called /lscratch. On a SLURM-based HPC, each job is assigned a global id ($SLURM_JOBID) and this is appended to the temp folder name for each process. This can be modified in the config.nf file. Thus, there is a requirement for :  
  
/lscratch folder for temporary files  
SLURM_JOBID global variable for each HPC job.  
  
### How to run:
nextflow run -c \<\<config file\>\> -profile \<\<profiles\>\> callSSDSpeaks.nf --tbed \<\<full path to ssDNA bed file\>\> --cbed \<\<full path to control ssDNA bed file\>\> --genome mm10 --name test --accessorydir \<\<full path to accessorydir folder (part of this repo)\>\> --outdir XX

3. Genome blacklist BED file (put in accessoryFiles/blacklist)  
   Blacklist files provided for mouse mm10 and human hg38 genomes. 
   A placeholder blacklist BED file must be used if blacklisting is not required or if blacklisted regions are unknown.
   
#### How to run (example on NIH biowulf):
```
module load nextflow singularity
  
cd /data/$USER && git clone https://github.com/kevbrick/callSSDSpeaks.git
  
curl https://raw.githubusercontent.com/nf-core/configs/master/conf/nihbiowulf.config >/data/$USER/callSSDSpeaks/nihbiowulf.config

nextflow run -c /data/$USER/callSSDSpeaks/config.nf,/data/$USER/callSSDSpeaks/nihbiowulf.config 
             -profile slurm /data/$USER/callSSDSpeaks.nf 
             --tbed /data/$USER/ssds/treatment.ssDNA_type1.bed 
             --cbed /data/$USER/ssds/control.ssDNA_type1.bed 
             --genome mm10 
             --name test 
             --accessorydir /data/$USER/callSSDSpeaks/accessoryFiles 
             --outdir /data/$USER/callSSDSpeaks_output
```

### Recommended: Singularity / Docker  
The dependencies for this pipeline are stored as a docker container that can be used by either Singularity (Tested) or Docker (Untested). 

### Alternative 1: Conda (not recommended)
Anaconda / miniconda 

### Conda environment: 
All dependencies can be installed using the included conda environment (accessoryFiles/conda/environment.yml). Although nextflow can take a conda env file as input, several of the packages will not work with the long path names used by nextflow. Instead, I recommend building the environment first, then passing the built environment in the nextflow config file.  
  
`conda env create --file accessoryFiles/conda/environment.yml`  
  
The path to the callSSDSHS conda env must be added in the configuration file (accessoryFiles/conf/config.nf).If you have an environment variable named $CONDA_ENVS pointing to your conda env folder, then config.nf can remain unchanged. 

### Alternative 2: Manual (not recommended): 
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



