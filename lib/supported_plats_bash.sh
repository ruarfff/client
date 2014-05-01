# !/bin/sh

function my_array {
	#echo "Waheyy Bosco!!"
	#echo $1

	FSUTILS_DIR=$1
	scanBinaries=( "$FSUTILS_DIR"/fsScan/* )
	reportBinaries=( "$FSUTILS_DIR"/fsReport/* )

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
