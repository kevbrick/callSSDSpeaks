#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// set some default params
params.help=""

// Pipeline version
version = '1.3'

if (params.help) {
  log.info"""
  ==============================================================================
  callSSDSpeaks v.${version}
  ------------------------------------------------------------------------------
  Usage:

  Mandatory arguments:
  -tbed     Treatment ssDNA type1 BED file ** SSDS BAM will not work **
  -cbed     Control ssDNA type1 BED file (Input or IgG (preferred))
  -genome   Genome (must be a folder name in $NXF_GENOMES)
  -name     Sample name

  Optional arguments:
  -blacklist BED file of blacklisted genomic regions.
             NOTE: a blacklist file is required, however, by default, the
             pipeline will look in the \$accessorydir/blacklist/\$genome folder
  -satcurve  (default: false)
  -reps      This pipeline can generate a peak calling saturation curve. This
             downsamples reads from the original BED file and calls peaks with
             each subset. This parameter defines how many subsets to take at each
             downsampling level (default = 3)
  -sctype    What range of values should be used for building sat curve? There
             are 3 options:
             standard (default): 20, 40, 60, 80, 100% of reads
             extended: 2.5, 5, 7.5, 10,20,30 ... 100% of reads
             minimal: 10, 50, 100% of reads

  """.stripIndent()
  exit 0
  }

// Check that Nextflow version is up to date enough
nf_required_version = '20.01.0'
try {
    if( ! nextflow.version.matches(">= $nf_required_version") ){
        throw GroovyException('Nextflow version too old')
    }
  } catch (all) {
    log.error "====================================================\n" +
              "  Nextflow version $nf_required_version required! You are running v$workflow.nextflow.version.\n" +
              "  Pipeline execution will continue, but things may break.\n" +
              "  Please run `nextflow self-update` to update Nextflow.\n" +
              "============================================================"
  }

// Configurable variables
params.tbed         = false
params.cbed         = false
params.genome       = false
params.name         = false
params.satcurve     = false
params.blacklist    = ''
params.pipedir      = ''
params.accessorydir = ''
params.sctype       = 'standard'
params.reps         = 3

// Set saturation curve thresholds
if (params.satcurve){

  if (params.sctype == 'expanded'){
    satCurvePCs  = Channel.from(0.025,0.05,0.075,0.10,0.20,0.30,0.40,0.50,0.60,0.70,0.80,0.90,1.00)
  }

  if (params.sctype == 'standard'){
    satCurvePCs  = Channel.from(0.20,0.40,0.60,0.80,1.00)
  }

  if (params.sctype == 'minimal'){
    satCurvePCs  = Channel.from(0.10,0.50,1.00)
  }

  useSatCurve  = true
  satCurveReps = params.reps-1

}else{
  satCurvePCs  = Channel.from(1.00)
  useSatCurve  = false
  satCurveReps = 0
}

def blackList  = file("${params.accessorydir}/blacklist/${params.genome}/blackList.bed")

def genome_fa  = "\$NXF_GENOMES/${params.genome}/genome.fa"
def genome_idx = "\$NXF_GENOMES/${params.genome}/genome.fa.fai"

def tBed = file(params.tbed)
def cBed = file(params.cbed)

if (!params.outdir){
  params.outdir = "./output_SSDShotspots"
  }

//log.info
log.info " "
log.info " =============================================================================="
log.info " callSSDSpeaks v.${version}"
log.info " ------------------------------------------------------------------------------"
log.info " --tbed         ${params.tbed} "
log.info " --cbed         ${params.cbed} "
log.info " --genome       ${params.genome} "
log.info " --genome_fa    ${genome_fa} "
log.info " --genome_idx   ${genome_idx} "
log.info " --name         ${params.name} "
log.info " --blacklist    ${blackList} "
if (useSatCurve){
  log.info " --satcurve     ${params.sctype} "
  log.info " --reps         ${satCurveReps} "
}
log.info " --pipedir      ${params.pipedir} "
log.info " --accessorydir ${params.accessorydir} "
log.info " --outdir       ${params.outdir} "
log.info " "
log.info "=========================================================================="

// Shuffle BED files so that downsampling is not biased
process shufBEDs {

  input:
  path(treatment_bed)
  path(control_bed)

  output:
  path("*.T.sq30.bed", emit: treatment)
  path("*.C.sq30.bed", emit: control)

  script:
  def treatment_Q30_bed      = treatment_bed.name.replaceFirst(".bed",".T.q30.bed")
  def treatment_Q30_shuf_bed = treatment_bed.name.replaceFirst(".bed",".T.sq30.bed")

  def control_Q30_bed        = control_bed.name.replaceFirst(".bed",".C.q30.bed")
  def control_Q30_shuf_bed   = control_bed.name.replaceFirst(".bed",".C.sq30.bed")

  """
  perl -lane '@F = split(/\\t/,\$_); @Q = split(/_/,\$F[3]); print join("\\t",@F) if (\$Q[0] >= 30 && \$Q[1] >= 30)' ${treatment_bed} >${treatment_Q30_bed}
  perl -lane '@F = split(/\\t/,\$_); @Q = split(/_/,\$F[3]); print join("\\t",@F) if (\$Q[0] >= 30 && \$Q[1] >= 30)' ${control_bed}   >${control_Q30_bed}

  shuf ${treatment_Q30_bed} |grep -P '^chr[0123456789IVLXYZW]+\\s' >${treatment_Q30_shuf_bed}
  shuf ${control_Q30_bed}   |grep -P '^chr[0123456789IVLXYZW]+\\s' >${control_Q30_shuf_bed}
  """
  }

// Call hotspots with each set of downsampled reads
process callPeaks {

  publishDir "${params.outdir}/saturation_curve/peaks", mode: 'copy', overwrite: true, pattern: "*peaks_sc.bed"
  publishDir "${params.outdir}/peaks",                  mode: 'copy', overwrite: true, pattern: "*peaks.be*"
  publishDir "${params.outdir}/peaks",                  mode: 'copy', overwrite: true, pattern: "*peaks.xls"
  publishDir "${params.outdir}/model",                  mode: 'copy', overwrite: true, pattern: "*model*"

  tag { shuffle_percent }

  input:
  path(treatment_bed)
  path(control_bed)
  path(blacklist_bed)
  val(shuffle_percent)
  path(accFiles)

  output:
  path("*peaks_sc.bed",   emit: allbed)
  path("*peaks.xls",      emit: peaks_xls, optional: true)
  path("*peaks.bed"     , emit: peaks_bed,  optional: true)
  path("*peaks.bedgraph", emit: peaks_bg,  optional: true)
  path("*model.R",        emit: model_R,   optional: true)
  path("*model.pdf",      emit: model_pdf, optional: true)

  script:
  """
  nT=`cat ${treatment_bed} |wc -l`
  nPC=`perl -e 'print int('\$nT'*${shuffle_percent})'`

  perl accessoryFiles/scripts/pickNlines.pl ${treatment_bed} \$nPC >\$nPC.tmp
  sort -k1,1 -k2n,2n -k3n,3n -k4,4 -k5,5 -k6,6 \$nPC.tmp |uniq >\$nPC.T.bed

  ## Just use chrom1: faster with analagous results
  grep -w chr1 \$nPC.T.bed >T.cs1.bed
  grep -w chr1 ${control_bed} >C.cs1.bed
  Rscript accessoryFiles/scripts/runNCIS.R T.cs1.bed C.cs1.bed accessoryFiles/NCIS NCIS.out
  ratio=`cut -f1 NCIS.out`

  ## GET GENOME SIZE - BLACKLIST SIZE
  tot_sz=`cut -f3 ${genome_idx} |tail -n1`
  bl_size=`perl -lane '\$tot+=(\$F[2]-\$F[1]); print \$tot' ${blacklist_bed} |tail -n1`
  genome_size=`expr \$tot_sz - \$bl_size`

  for i in {0..${satCurveReps}}; do
    thisName=${params.name}'.N'\$nPC'_${shuffle_percent}pc.'\$i
    perl accessoryFiles/scripts/pickNlines.pl ${treatment_bed} \$nPC >\$nPC.tmp

    sort -k1,1 -k2n,2n -k3n,3n -k4,4 -k5,5 -k6,6 \$nPC.tmp |uniq >\$nPC.T.bed

    macs2 callpeak --ratio \$ratio \\
      -g \$genome_size \\
      -t \$nPC.T.bed \\
      -c ${control_bed} \\
      --bw 1000 \\
      --keep-dup all \\
      --slocal 5000 \\
      --name \$thisName

    intersectBed -a \$thisName'_peaks.narrowPeak' -b ${blacklist_bed} -v >\$thisName'.peaks_sc.noBL'

    cut -f1-3 \$thisName'.peaks_sc.noBL' |grep -v ^M |grep -v chrM |sort -k1,1 -k2n,2n >\$thisName'_peaks_sc.bed'
    mv \$thisName'_peaks.xls' \$thisName'_peaks_sc.xls'
  done

  sort -k1,1 -k2n,2n -k3n,3n ${params.name}*peaks_sc.bed |mergeBed -i - >${params.name}.${shuffle_percent}.peaks_sc.bed

  if [ ${shuffle_percent} == 1.00 ]; then
    mv ${params.name}.${shuffle_percent}.peaks_sc.bed ${params.name}.peaks.bed
    cat *1.00*.r >${params.name}.model.R
    R --vanilla <${params.name}.model.R
    cat *1.00pc.0_peaks_sc.xls >${params.name}.peaks.xls

    ## Calculate strength
    perl accessoryFiles/scripts/normalizeStrengthByAdjacentRegions.pl --bed ${params.name}.peaks.bed \
         --in ${treatment_bed} --out ${params.name}.peaks.bedgraph --rc
  fi
  """
  }

// Make saturation curve from called peak sets
process makeSatCurve {

  publishDir "${params.outdir}/saturation_curve",  mode: 'copy', overwrite: true

  input:
  path(saturation_curve_data)
  path(accFiles)

  output:
  path("*satCurve.tab", emit: table)
  path("*.png", emit: png)

  script:
  """
  #!/usr/bin/perl
  use strict;

  my \$tf = "satCurve.tab";

  open TMP, '>', \$tf;
  print TMP join("\\t","reads","pc","hs")."\\n";

  open my \$IN, '-|', 'wc -l *peaks_sc.bed |grep -v total |sort -k1n,1n ';

  while (<\$IN>){
  	chomp;
  	next if (\$_ =~ /\\stotal\\s*\$/);
  	\$_ =~ /^\\s*(\\d+).+\\.N(\\d+)_([\\d\\.]+)pc.+\$/;
  	my (\$HS,\$N,\$pc) = (\$1,\$2,\$3*100);
  	print TMP join("\\t",\$N,\$pc,\$HS)."\\n";
  }

  close TMP;
  close \$IN;

  my \$R = \$tf.'.R';

  makeRScript(\$R,"${params.name}.satCurve.tab","${params.name}");

  system('R --vanilla <'.\$R);

  sub makeRScript{
  	my (\$sName,\$data,\$sampleName) = @_;
  	open RS, '>', \$sName;
  	print RS 'source("accessoryFiles/scripts/satCurveHS.R")'."\\n";
  	print RS 'satCurveHS(fIN = "'.\$tf.'", sampleName = "'.\$sampleName.'")'."\\n";
  	close RS;
  }
  """
  }

// OK ... let's start
workflow {
 
  accFiles  = channel.fromPath("${params.accessorydir}")
  shuf_beds = shufBEDs(tBed,cBed)
  peaks     = callPeaks(shuf_beds.treatment, shuf_beds.control, blackList, satCurvePCs, accFiles.collect())

  if (useSatCurve){
    satcurve  = makeSatCurve(peaks.allbed.collect(),accFiles.collect())
  }

}
