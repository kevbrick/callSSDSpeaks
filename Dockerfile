FROM nfcore/base:1.10.2

LABEL authors="Kevin Brick" \
      description="Docker image containing all software requirements for the SSDS peak calling pipeline"

## Install gcc
RUN apt-get update
RUN apt-get -y --force-yes install libblas-dev

COPY env2.yml /
RUN conda env create --quiet -f environment.yml && conda clean -a

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /opt/conda/envs/callSSDSpeaks/bin:$PATH

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name callSSDSpeaks > callSSDSpeaks.yml

# Instruct R processes to use these empty files instead of clashing with a local version
RUN touch .Rprofile
RUN touch .Renviron
