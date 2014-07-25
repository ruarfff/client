#!/bin/sh

# Need root or sudo to allow chmod and ensure fsscan runs smoothly
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root or sudo" 1>&2
   exit 1
fi


################################## Properties ###################################

# Working DIR should be where the fsscan app and this script are and
# not neccessarily where the script is run from.
pushd "$(dirname "$0")" > /dev/null
WORKING_DIR=$(pwd)
popd > /dev/null


# Intializing default SYSTEM and PROCESSOR values that will be updated in 
# a call to the determineSystemAndArchitecture function
SYSTEM="Unknown"
PROCESSOR="Unknown"

. "$WORKING_DIR/lib/system_checker.sh"
determineSystemAndArchitecture

DTLS_TO_PROCESS=""
FSUTILS_DIR="$WORKING_DIR/fsUtils"
LOG_DIR="$WORKING_DIR/logs"
REPORT_DIR="$FSUTILS_DIR/reports"

FSSCAN="$FSUTILS_DIR/bin/fsscan$SYSTEM$PROCESSOR" 
FSREPORT="$FSUTILS_DIR/bin/fsReport$SYSTEM$PROCESSOR"
REPORT_CONFIG="$WORKING_DIR/config/report/NFS.cfg"

# Parameter Variables, initialized with some default values
ACTION="all"
LOCATION="/"
CONFIG="$WORKING_DIR/config/scan/scan-nix.cfg"
DTL="$WORKING_DIR/DTLs/fsScan.dtl"
TAG="FSMA_RPT"
LOG="$LOG_DIR/fsScan.log"
ERR="$LOG_DIR/fsErrScan.log"
OUTPUT="$WORKING_DIR/fsReport.tar.gz"
TEMP="$WORKING_DIR/tmp"


################################## Functions ##################################


# Creates any directories needed for reporting if they don't exist already
setupDirectories () {
	mkdir -p "$(dirname "${LOG}")";
	mkdir -p "$(dirname "${ERR}")";
	mkdir -p "$(dirname "${DTL}")";
	mkdir -p "$TEMP";	
}

# Ensure that required binaries can be executed
setPermissions () {
	chmod u+x "$FSSCAN";
	chmod u+x "$FSREPORT";
}

# Run a file system scan and store the resulting DTL file 
runScan () {
	if [ -f "$FSSCAN" ]
	then
		# Tell the user what's going to happen
		echo " "
		echo " "
		echo "Running command:"
		echo "$FSSCAN $LOCATION -dtl $DTL -tag $TAG -log $LOG -err $ERR -cfg $CONFIG"
		echo "Please wait......."
		$FSSCAN $LOCATION -dtl "$DTL" -tag $TAG -log "$LOG" -err "$ERR" -cfg "$CONFIG";
		echo "Scan finished"
		echo
	else
		echo "ERROR"
		echo "No scan executable available for $SYSTEM $PROCESSOR"
	fi
}

# Print out a list of what platforms the fsma-client can be run on
listSupportedPlatforms () {
	echoAvailableBinaries "$FSUTILS_DIR"
}


# Run reports on the DTLs defined as arguments to this script 
runReport () {
	if [ $DTLS_TO_PROCESS = "" ] ; then
		List=$DTLS_TO_PROCESS
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
		"$FSREPORT" -dtl "$DTL" -cfg "$REPORT_CONFIG" -rdir "$REPORT_DIR"; 
		echo "Creating output file: $OUTPUT"
		rm -rf fsUtils/output;
		mkdir fsUtils/output;
		cp "$REPORT_DIR/*" fsUtils/output;
		cp "$LOG" fsUtils/output;
		cp "$ERR" fsUtils/output;
		cd fsUtils/output;
		tar -zcvf "$OUTPUT" .;
		cd "$WORKING_DIR"; 
		rm -rf fsUtils/output;
		rm -rf "$REPORT_DIR";

		echo "Reporting finished"
		echo "Outputs written to $OUTPUT"
		echo
	else
		echo "ERROR"
		echo "No report executable available for $SYSTEM $PROCESSOR"
	fi
}

checkSupported () {
	if [ -f "$FSSCAN" ] && [ -f "$FSREPORT" ]; then
		echo; echo "Supported"; echo
		echo "fsScan and fsReport for platform: \"$SYSTEM\" and architecture: \"$PROCESSOR\" are supported"; echo
	else
		if [ -f "$FSSCAN" ]; then
			echo; echo "Scan Only"; echo
			echo "fsScan (but not fsReport) for platform: \"$SYSTEM\" and architecture: \"$PROCESSOR\" is supported"; echo
		else
			if [ -f "$FSREPORT" ]; then
				echo; echo "Report Only"; echo
				echo "fsReport (but not fsScan) for platform: \"$SYSTEM\" and architecture: \"$PROCESSOR\" is supported"; echo
			else
				echo; echo "Not Supported"; echo
				echo "fsScan and fsReport for platform: \"$SYSTEM\" and architecture: \"$PROCESSOR\" are NOT supported"; echo
			fi
		fi
	fi
}

# Initialising arrays with the output of a command is done differently on bash
# vs ksh
THIS_SHELL=$(echo "$SHELL" | awk -F/ '{print $NF}')
if [ "$THIS_SHELL" = "ksh" ]; then
	. "$WORKING_DIR/lib/supported_plats_ksh.sh"
fi
if [ "$THIS_SHELL" = "bash" ]; then
	. "$WORKING_DIR/lib/supported_plats_bash.sh"
fi

################################## Start script setup and user interaction ##################################

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
						echo " -a|--action inputs: scan, report or all - default to all which is a scan and report" 
  						echo " -l|--location : folder to scan, defaults to root file system" 
  						echo " -v|--version : Print the version of the fsma-client"
  						echo " -i|--isSupported : Check if the current system is supported by fsma-client"
  						echo " -s|--supportedPlatforms : Prints out all platforms that this fsma-client supports"
  						echo " -cfg : location of scan config file, default to ./scan.cfg" 
  						echo " -dtl : path to DTL files, defaults to ./DTLs/fsScan.dtl"
  						echo " -tag : tag to pass to scan, defaults to FSMA_RPT"
  						echo " -log : log files, default to ./Logs/fsScan.log" 
  						echo " -err : error logs, default to ./Logs/fsErrScan.log"
  						echo " -output : zip archive containing fsReport output, defaults to ./fsReport.zip" 
  						echo " -temp : folder for temporary working files, defaults to ./tmp"
  						echo " "
  						exit 0
                        ;;
                -a|--action)
                     	shift
                        if test $# -gt 0; then
                                export ACTION=$1
                        else
                                echo " -action option was used but no action was specified"
                                exit 1
                        fi
                        shift   
                        ;;
                -l|--location)
                     	shift
                        if test $# -gt 0; then
                                export LOCATION=$1
                        else
                                echo " -location option was used but no scan location was specified"
                                exit 1
                        fi
                        shift   
                        ;;
                 -v|--version)
						echo; cat "$WORKING_DIR/MANIFEST.MF"; echo; echo;
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
                -o|--output)
                        shift
                        if test $# -gt 0; then
                                export OUTPUT=$1
                        else
                                echo "no output file specified"
                                exit 1
                        fi
                        shift
                        ;;
                -cfg)
                        shift
                        if test $# -gt 0; then
                                export CONFIG=$1
                        else
                                echo " -cfg option was used but no config file was specified"
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
                                echo " -dtl option was used but no dtl file specified"
                                exit 1
                        fi
                        shift
                        ;;                
                -tag)
                        shift
                        if test $# -gt 0; then
                                export TAG=$1
                        else
                                echo " -tag option was used but no tag was specified"
                                exit 1
                        fi
                        shift
                        ;;
                -log)
                        shift
                        if test $# -gt 0; then
                                export LOG=$1
                        else
                                echo " -log option was used but no log file specified"
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
                *)
                        break
                        ;;
        esac
done	

setupDirectories
setPermissions

if test "$ACTION" = "all"; then
	
	runScan
	runReport

elif test "$ACTION" = "scan"; then
	
	runScan	

elif test "$ACTION" = "report"; then
	
	runReport

else
	echo "Invalid action provided. Valid actions are scan, report or all"
	exit 1
fi



exit 0