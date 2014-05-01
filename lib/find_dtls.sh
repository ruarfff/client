#!/bin/sh
DTLSTOPROCESS=""
function ProcessDTLS () {
	#inVals=`echo $1 | sed s/','/' '/g`
	inVals=$1
	OIFS="$IFS"
	IFS=$','
	for input in $inVals
	do
		if [ -d $input ] ; then #search from here for all dtl files and add each to the array
			workingDir=`pwd`
			AllObjs=`find $workingDir/ -print`
				for fildir in $input/*.dtl
				do
					if [ -f $fildir ] ; then
						ProcessDTLS $fildir
					fi
				done
		elif [ -f $input ] ; then # just add this file to the array
			handleDTLFile $input
		else
			echo "\nError: $input not a file or directory"
		fi
		
	done
	IFS="$OIFS"
}

function handleDTLFile () {
	#insert spaces for commas (if some subdirs contain spaces in name, this causes problems in the loop)
	if [[ $1 == *.dtl ]] ; then
		addDTLtoProcessList $input
	else
		echo "\nError: $input is not a .dtl file"]
	fi
}

function addDTLtoProcessList (){
	#add dtl file path to list of files to be processed
	export DTLSTOPROCESS="$DTLSTOPROCESS $1"
} 
ProcessDTLS $1
echo $DTLSTOPROCESS
