# !/bin/sh

function echoAvailableBinaries {
	FSUTILS_DIR=$1
	binaries=( "$FSUTILS_DIR"/bin/* )

	echo; echo "Support platforms and architectures for fsScan are : "; echo
	for scanBinary in "${binaries[@]}"; do
		
		if [[ $(basename $scanBinary) == fsScan*.exe ]] ; then
			echo "Windows"
		elif [[ $(basename $scanBinary) == fsScan* ]] ; then
			echo $scanBinary | awk -F/ '{print $NF}' | sed 's/^fsScan//g'
		fi

	done
	echo; echo; echo "Support platforms and architectures for fsReport are : "; echo
	for reportBinary in "${binaries[@]}"; do

		if [[ $(basename $reportBinary) == fsScan*.exe ]] ; then
			echo "Windows"
		elif [[ $(basename $reportBinary) == fsReport* ]] ; then
			echo $reportBinary | awk -F/ '{print $NF}' | sed 's/^fsReport//g'	
		fi
				
	done
	echo
}
