#!/usr/bin/env nextflow
/*
vim: syntax=groovy
-*- mode: groovy;-*-
========================================================================================
               QBIC-megSAP-Pipeline    B E S T    P R A C T I C E
========================================================================================
 Medical genetics analysis pipeline (imgag/megSAP). Started in October 2017.
 #### Homepage / Documentation
 https://github.com/qbicsoftware/QBIC-megSAP-NGS
 #### Authors
 Alexander Peltzer <alexander.peltzer@qbic.uni-tuebingen.de>
----------------------------------------------------------------------------------------
*/

//Version of the pipeline

version=1.0

def helpMessage() {
    log.info"""
    =========================================
    QBIC-megSAP-Pipeline v${version}
    =========================================
    Usage:

    There are three different commands available in the pipeline. For now, we only support the standard analysis procedure that produces BAM files within this script.

    - DNA: Single sample analysis
    - DNA: Multi sample analysis ( and trio ) 
    - RNA: Expression analysis

    DNA-Single Sample parameters:

	Mandatory parameters:
  		-folder <string>         Analysis data folder.
  		-name <string>           Base file name, typically the processed sample ID (e.g. 'GS120001_01').

	Optional parameters:
  		-system <infile>         Processing system INI file (determined from NGSD via the 'name' by default).
  		-steps <string>          Comma-separated list of steps to perform:
        		                 ma=mapping, vc=variant calling, an=annotation, db=import into NGSD, cn=copy-number analysis.
                		         Default is: 'ma,vc,an,db,cn'.
  		-backup                  Backup old analysis files to old_[date] folder.
  		-lofreq                  Add low frequency variant detection.
  		-threads <int>           The maximum number of threads used.
      		                     Default is: '2'.
  		-thres <int>             Splicing region size used for annotation (flanking the exons).
       		                     Default is: '20'.
  		-clip_overlap            Soft-clip overlapping read pairs.
  		-no_abra                 Skip realignment with ABRA.
  		-out_folder <string>     Folder where analysis results should be stored. Default is same as in '-folder' (e.g. Sample_xyz/).
                           Default is: 'default'.

	Special parameters:
  		--log <file>             Enables logging to the specified file.
  		--conf <file>            Uses the given configuration file.
  		--tdx                    Writes a Tool Defition XML file.
  		--email                  Sends you an e-mail on success/fail/etc (NOT YET IMPLEMENTED)

  	DNA-Multi Sample parameters: TBD

  	RNA Expression parameters: TBD
 """
}

//Help message if nothing else is specified

params.help = false

if(params.help){
	helpMessage()
	exit 0
}

//Check NF version similar to NGI-RNAseq, thanks guys!

nf_required_version = '0.25.0'
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

//We're using the same defaults as in the original workflow specification here

params.folder = false
params.name = false
params.system = false
params.steps = "ma,vc,an,cn" //db import not for us, just at IMGAG
params.backup = false
params.lofreq = false
params.threads = '2'
params.thres = '20'
params.clip_overlap = false
params.no_abra = false
params.out_folder = 'default'
params.log = false
params.conf = false
params.tdx = false
params.multiqc_config = "$baseDir/conf/multiqc_config.yaml"

multiqc_config = file(params.multiqc_config)


//Validate inputs

if( params.folder ) {
	folder = Channel
		.fromPath(params.folder)
		.ifEmpty{exit 1, "Your input folder was not specified correctly"}
		.into(folder_ch)

}

if (params.name) {
	name = Channel
		.fromPath(params.name)
		.ifEmpty{exit 1, "The file identifier was not specified correctly."}
		.into(name_ch)
}



//Header log info

log.info "========================================="
log.info " QBIC-megSAP-NGS : v${version}"
log.info "========================================="

params.folder = false
params.name = false
params.system = false
params.steps = "ma,vc,an,cn" //db import not for us, just at IMGAG
params.backup = false
params.lofreq = false
params.threads = '2'
params.thres = '20'
params.clip_overlap = false
params.no_abra = false
params.out_folder = 'default'
params.log = false
params.conf = false
params.tdx = false
params.multiqc_config = "$baseDir/conf/multiqc_config.yaml"


def summary = [:]
summary['Folder']     = custom_runName ?: workflow.runName
summary['Name']        = params.reads
summary['System']    = params.singleEnd ? 'Single-End' : 'Paired-End'
summary['Steps']       = params.genome
summary['Backup'] = ( unstranded ? 'None' : forward_stranded ? 'Forward' : reverse_stranded ? 'Reverse' : 'None' )
summary['Low Frequency'] = clip_r1
summary['Threads'] = clip_r2
summary["Threshold"] = three_prime_clip_r1
summary["Clip Overlap"] = three_prime_clip_r2
summary["Logfile"] = three_prime_clip_r2
summary["Special configuration"] = three_prime_clip_r2
summary["TDX"] = three_prime_clip_r2

if(params.email) summary['E-Mail address'] = params.email
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="


/*
Run megSAP-analyze.php with selected parameters on input file(s)
*/

process single_sample_analysis {
	tag "$name"
	publishDir "${params.out_folder}", mode: 'move'

	//publishDirs etc?

	input:
	file folder_path from folder_ch

	output:

	script:
	"""
	php /megSAP/src/Pipelines/analyze.php -folder ${folder_path}

	"""

/*-folder <string>         Analysis data folder.
  		-name <string>           Base file name, typically the processed sample ID (e.g. 'GS120001_01').

	Optional parameters:
  		-system <infile>         Processing system INI file (determined from NGSD via the 'name' by default).
  		-steps <string>          Comma-separated list of steps to perform:
        		                 ma=mapping, vc=variant calling, an=annotation, db=import into NGSD, cn=copy-number analysis.
                		         Default is: 'ma,vc,an,db,cn'.
  		-backup                  Backup old analysis files to old_[date] folder.
  		-lofreq                  Add low frequency variant detection.
  		-threads <int>           The maximum number of threads used.
      		                     Default is: '2'.
  		-thres <int>             Splicing region size used for annotation (flanking the exons).
       		                     Default is: '20'.
  		-clip_overlap            Soft-clip overlapping read pairs.
  		-no_abra                 Skip realignment with ABRA.
  		-out_folder <string>     Folder where analysis results should be stored. Default is same as in '-folder' (e.g. Sample_xyz/).
                           Default is: 'default'.

	Special parameters:
  		--log <file>             Enables logging to the specified file.
  		--conf <file>            Uses the given configuration file.
  		--tdx                    Writes a Tool Defition XML file.
  		--email                  Sends you an e-mail on success/fail/etc (NOT YET IMPLEMENTED)

  		*/

}