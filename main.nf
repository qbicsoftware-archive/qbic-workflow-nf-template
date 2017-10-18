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
  		--help                   Shows this help.
  		--version                Prints version and exits.
  		--verbose                Verbose error messages including traceback.
  		--log <file>             Enables logging to the specified file.
  		--log_id <id>            Uses the given identifier for logging.
  		--conf <file>            Uses the given configuration file.
  		--tdx                    Writes a Tool Defition XML file.

 """