#!/bin/sh

# Need root or sudo to allow chmod and ensure fsscan runs smoothly
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root or sudo" 1>&2
   exit 1
fi

# Working DIR should be where the fsscan app and this script are and
# not neccessarily where the script is run from.
WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Initialising arrays with the output of a command is done differently on bash
# vs ksh
THIS_SHELL=`echo $SHELL | awk -F/ '{print $NF}'`
if [ $THIS_SHELL = "ksh" ]; then
	. $WORKING_DIR/lib/supported_plats_ksh.sh
fi
if [ $THIS_SHELL = "bash" ]; then
	. $WORKING_DIR/lib/supported_plats_bash.sh
fi

PLATFORM=$(uname -s)
# On HP-UX, architecture is retrieved with : uname -m
if [ "$PLATFORM" = "HP-UX" ]; then
	# convert any '/' in output to '_'
	ARCHITECTURE=$(uname -m | sed 's/\//_/g')
else
	ARCHITECTURE=$(uname -p)
fi

if [ "$PLATFORM" = "SunOS" ]; then
	PLATFORM="Solaris"
	ARCHITECTURE=`uname -p`
elif  [ "$PLATFORM" = "AIX" ] ; then
	PLATFORM="AIX"
	ARCHITECTURE="`uname -p``getconf MACHINE_ARCHITECTURE``getconf KERNEL_BITMODE`"
elif [ "$PLATFORM" = "Linux" ] ; then
	ARCHITECTURE=`uname -p`
	if [ -f /etc/fedora-release ] ; then
		PLATFORM='Fedora'
	elif [ -f /etc/SuSE-release ] ; then
		PLATFORM=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
	elif [ -f /etc/redhat-release ]; then
		OS='RHEL'	
		PLATFORM="$OS"
	elif [ -f /etc/debian_version ] ; then
		#relies on Ubuntu being the first word
		VER="`cat /etc/issue | cut -b 1-6`"
		if [ "Ubuntu" = "$VER" ]; then
			PLATFORM="Ubuntu"
		else
			PLATFORM="`cat /etc/debian_version`"
		fi
	fi
elif [ "$PLATFORM"="HP-UX" ] ; then
	MOD=`uname -m`
	PLATFORM="HPUX"
	ITAN="ITANIUM"
	RISC="PARISC"
	if [ "$MOD" = "ia64" ] ; then
		OS="$PLATFORM"
		ARCHITECTURE="$ITAN`uname -m | sed 's/\//_/g'`"
	else
		OS="$PLATFORM"
		ARCHITECTURE="$RISC`uname -m | sed 's/\//_/g'`"
	fi
	

fi

DTLSTOPROCESS=""
FSUTILS_DIR="$WORKING_DIR/fsUtils"
LOG_DIR="$WORKING_DIR/logs"
REPORT_DIR="$FSUTILS_DIR/reports"

FSSCAN="$FSUTILS_DIR/fsScan/fsscan$PLATFORM$ARCHITECTURE" 
FSREPORT="$FSUTILS_DIR/fsReport/fsReport$PLATFORM$ARCHITECTURE"
REPORT_CONFIG="$WORKING_DIR/config/report/NFS.cfg"

# Parameter Variables
ACTION="all"
LOCATION="/"
CONFIG="$WORKING_DIR/config/scan/scan-nix.cfg"
DTL="$WORKING_DIR/DTLs/fsScan.dtl"
TAG="FSMA_RPT"
LOG="$LOG_DIR/fsScan.log"
ERR="$LOG_DIR/fsErrScan.log"
OUTPUT="$WORKING_DIR/fsReport.tar.gz"
TEMP="$WORKING_DIR/tmp"


# Functions

function SetUpDirectories {
	echo "$(dirname ${TEMP})"
	mkdir -p $(dirname ${LOG});
	mkdir -p $(dirname ${ERR});
	mkdir -p $(dirname ${DTL});
	mkdir -p $TEMP;	
}

function SetPermissions {
	chmod u+x $FSSCAN;
	chmod u+x $FSREPORT;
}

function RunScan {
	if [ -f "$FSSCAN" ]
	then
		# Tell the user what's going to happen
		echo " "
		echo " "
		echo "Running command:"
		echo "$FSSCAN $LOCATION -dtl $DTL -tag $TAG -log $LOG -err $ERR -cfg $CONFIG"
		echo "Please wait......."
		$FSSCAN $LOCATION -dtl $DTL -tag $TAG -log $LOG -err $ERR -cfg $CONFIG;
		echo "Scan finished"
		echo
	else
		echo "ERROR"
		echo "No scan executable available for $PLATFORM $ARCHITECTURE"
	fi
}

function RunReport {
	if [ DTLSTOPROCESS = "" ] ; then
		List=$DTLSTOPROCESS
	else
		List=$DTL
	fi

	if [ -f "$FSREPORT" ]
	then
		# Tell the user what's going to happen
		echo " "
		echo " "
		echo "Running command:"
		echo "$FSREPORT -dtl $DTL -cfg $REPORT_CONFIG"
		echo "Please wait......."
		$FSREPORT -dtl $DTL -cfg $REPORT_CONFIG -rdir $REPORT_DIR; 
		echo "Creating output file: $OUTPUT"
		rm -rf fsUtils/output;
		mkdir fsUtils/output;
		cp $REPORT_DIR/* fsUtils/output;
		cp $LOG fsUtils/output;
		cp $ERR fsUtils/output;
		cd fsUtils/output;
		tar -zcvf $OUTPUT .;
		cd $WORKING_DIR; 
		rm -rf fsUtils/output;
		rm -rf $REPORT_DIR;

		echo "Reporting finished"
		echo "Outputs written to $OUTPUT"
		echo
	else
		echo "ERROR"
		echo "No report executable available for $PLATFORM $ARCHITECTURE"
	fi
}

function checkSupported {
	if [ -f "$FSSCAN" ] && [ -f "$FSREPORT" ]; then
		echo; echo "Supported"; echo
		echo "fsScan and fsReport for platform: \"$PLATFORM\" and architecture: \"$ARCHITECTURE\" are supported"; echo
	else
		if [ -f "$FSSCAN" ]; then
			echo; echo "Scan Only"; echo
			echo "fsScan (but not fsReport) for platform: \"$PLATFORM\" and architecture: \"$ARCHITECTURE\" is supported"; echo
		else
			if [ -f "$FSREPORT" ]; then
				echo; echo "Report Only"; echo
				echo "fsReport (but not fsScan) for platform: \"$PLATFORM\" and architecture: \"$ARCHITECTURE\" is supported"; echo
			else
				echo; echo "Not Supported"; echo
				echo "fsScan and fsReport for platform: \"$PLATFORM\" and architecture: \"$ARCHITECTURE\" are NOT supported"; echo
			fi
		fi
	fi
}

function listSupportedPlatforms {
	my_array $FSUTILS_DIR
}

# Fetch command line arguments

while test $# -gt 0; do
        case "$1" in
                -h|--help)
						echo " "
						echo "FSMA Client - EMC FSMA Client File System Scanning and Reporting Utility"
                        echo " "
                        echo "FSMA Client [options] application [arguments]"
                        echo " "
                        echo "options:"
						echo "-action scan | report | all : default to all which is a scan and report" 
  						echo "-location : folder to scan, defaults to root file system" 
  						echo "-cfg : location of scan config file, default to ./scan.cfg" 
  						echo "-dtl : path to DTL files, defaults to ./DTLs/fsScan.dtl"
  						echo "-tag : tag to pass to scan, defaults to FSMA_RPT"
  						echo "-log : log files, default to ./Logs/fsScan.log" 
  						echo "-err : error logs, default to ./Logs/fsErrScan.log"
  						echo "-output : zip archive containing fsReport output, defaults to ./fsReport.zip" 
  						echo "-temp : folder for temporary working files, defaults to ./tmp"
  						echo " "
  						exit 0
                        ;;
                -action)
                     	shift
                        if test $# -gt 0; then
                                export ACTION=$1
                        else
                                echo "-action option was used but no action was specified"
                                exit 1
                        fi
                        shift   
                        ;;
                -location)
                     	shift
                        if test $# -gt 0; then
                                export LOCATION=$1
                        else
                                echo "-location option was used but no scan location was specified"
                                exit 1
                        fi
                        shift   
                        ;;                
                -cfg)
                        shift
                        if test $# -gt 0; then
                                export CONFIG=$1
                        else
                                echo "-cfg option was used but no config file was specified"
                                exit 1
                        fi
                        shift
                        ;;
                -dtl)
                        shift
                        if test $# -gt 0; then
								#$1 is a comma separated list of values. either files or dirs
								#ProcessDTLS $1 
                                export DTL=$1
                        else
                                echo "-dtl option was used but no dtl file specified"
                                exit 1
                        fi
                        shift
                        ;;                
                -tag)
                        shift
                        if test $# -gt 0; then
                                export TAG=$1
                        else
                                echo "-tag option was used but no tag was specified"
                                exit 1
                        fi
                        shift
                        ;;
                -log)
                        shift
                        if test $# -gt 0; then
                                export LOG=$1
                        else
                                echo "-log option was used but no log file specified"
                                exit 1
                        fi
                        shift
                        ;;
                -err)
                        shift
                        if test $# -gt 0; then
                                export ERR=$1
                        else
                                echo "no error output file specified"
                                exit 1
                        fi
                        shift
                        ;;
                -output)
                        shift
                        if test $# -gt 0; then
                                export OUTPUT=$1
                        else
                                echo "no output file specified"
                                exit 1
                        fi
                        shift
                        ;;
                -temp)
                        shift
                        if test $# -gt 0; then
                                export TEMP=$1
                        else
                                echo "no temp directory specified"
                                exit 1
                        fi
                        shift
                        ;;
				-v|--version)
						echo; cat $WORKING_DIR/MANIFEST.MF; echo; echo;
						exit 0
						;;
				-i|--isSupported)
						checkSupported
						exit 0
						;;
				-s|--supportedPlatforms)
						listSupportedPlatforms
						exit 0
						;;
                *)
                        break
                        ;;
        esac
done	

SetUpDirectories
SetPermissions

if test $ACTION = "all"; then
	
	RunScan
	RunReport

elif test $ACTION = "scan"; then
	
	RunScan	

elif test $ACTION = "report"; then
	
	RunReport

else
	echo "Invalid action provided. Valid actions are scan, report or all"
	exit 1
fi



exit 0