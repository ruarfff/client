# !/bin/sh

function my_array {
	FSUTILS_DIR=$1
	output=$(ls $FSUTILS_DIR/fsScan/); set -A scanBinaries $output
	output=$(ls $FSUTILS_DIR/fsReport/); set -A reportBinaries $output

	echo; echo "Support platforms and architectures for fsScan are : "; echo
	for scanBinary in ${scanBinaries[@]}; do
		echo $scanBinary | awk -F/ '{print $NF}' | sed 's/^fsscan//g'
	done
	echo; echo; echo "Support platforms and architectures for fsReport are : "; echo
	for reportBinary in ${reportBinaries[@]}; do
		echo $reportBinary | awk -F/ '{print $NF}' | sed 's/^fsReport//g'
	done
	echo
}
