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

//singularity.enabled = true
//singularity.autoMounts = true
//singularity.envWhitelist='https_proxy,http_proxy,ftp_proxy,DISPLAY'

profiles {
  standard{
    process{
      executor = 'slurm'
      errorStrategy = 'retry'
      maxRetries = 0

      scratch = '/lscratch/$SLURM_JOBID'
      clusterOptions = ' --gres=lscratch:600 '
      conda = "$CONDA_ENVS/callSSDSHS/"

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
  }

  local {
    process{
      executor = 'local'
      errorStrategy = 'retry'
      maxRetries = 1

      scratch = '/lscratch/$SLURM_JOBID'
      clusterOptions = ' --gres=lscratch:50 '
      conda = "$CONDA_ENVS/callSSDSHS/"

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
 }
}
