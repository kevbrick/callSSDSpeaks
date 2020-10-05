params.pipedir="${baseDir}"
params.outdir="output"
params.accessorydir = "${params.pipedir}/accessoryFiles/"

timeline {
  enabled = true
  file = "${params.outdir}/nextflow/callSSDSpeaks_timeline.html"
}

report {
  enabled = true
  file = "${params.outdir}/nextflow/callSSDSpeaks_report.html"
}

trace {
  enabled = true
  file = "${params.outdir}/nextflow/callSSDSpeaks_trace.txt"
}

manifest {
  description = 'Call hotspots from SSDS data. Author: Kevin Brick.'
}

process.container = 'kevbrick/callssdspeaks:1.3'

executor = 'slurm'

profiles {
  conda { process.conda = "$baseDir/environment.yml" }
  debug { process.beforeScript = 'echo $HOSTNAME' }

  docker {
    docker.enabled = true
    // Avoid this error:
    //   WARNING: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.
    // Testing this in nf-core after discussion here https://github.com/nf-core/tools/pull/351
    // once this is established and works well, nextflow might implement this behavior as new default.
    docker.runOptions = '-u \$(id -u):\$(id -g)'
  }

  singularity {
    singularity.enabled = true
    singularity.autoMounts = true
    singularity.envWhitelist='https_proxy,http_proxy,ftp_proxy,DISPLAY,NXF_GENOMES'
    singularity.runOptions=' -B $NXF_GENOMES'
  }

  local {
    executor = 'local'
  }

  standard {
    executor = 'slurm'
  }
}

process{
  errorStrategy = 'retry'
  maxRetries = 0

  scratch = '/lscratch/$SLURM_JOBID'
  clusterOptions = ' --gres=lscratch:600 '


  withName:shufBEDs{
    cpus = { 2 }
    memory = { 4.GB }
    time = { 2.h * task.attempt }
  }

  withName:callPeaks{
    clusterOptions = ' --cpus-per-task=6 --mem=32g --gres=lscratch:100 '
    time           = { 6.h * task.attempt }
  }

  withName:makeSatCurve{
    clusterOptions = ' --cpus-per-task=2 --mem=4g --gres=lscratch:10 '
    time           = { 0.5.h * task.attempt }
  }
}

