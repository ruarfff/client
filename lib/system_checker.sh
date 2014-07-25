# Queries the shell for details about the system and processor
# Sets script level variables for usage in selecting the correct 
# binaries to run or to display an error message
determineSystemAndArchitecture () {
	SYSTEM=$(uname -s)
	# On HP-UX, architecture is retrieved with : uname -m
	if [ "$SYSTEM" = "HP-UX" ]; then
		# convert any '/' in output to '_'
		PROCESSOR=$(uname -m | sed 's/\//_/g')
	else
		PROCESSOR=$(uname -p)
	fi

	if [ "$SYSTEM" = "SunOS" ]; then
		SYSTEM="Solaris"
		PROCESSOR=$(uname -p)
	elif  [ "$SYSTEM" = "AIX" ] ; then
		SYSTEM="AIX"
		PROCESSOR="$(uname -p)$(getconf MACHINE_ARCHITECTURE)$(getconf KERNEL_BITMODE)"
	elif [ "$SYSTEM" = "Linux" ] ; then
		PROCESSOR=$(uname -p)
		if [ -f /etc/fedora-release ] ; then
			SYSTEM='Fedora'
		elif [ -f /etc/SuSE-release ] ; then
			SYSTEM=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
		elif [ -f /etc/redhat-release ]; then
			OS='RHEL'	
			SYSTEM="$OS"
		elif [ -f /etc/debian_version ] ; then
			#relies on Ubuntu being the first word
			VER="$(cat /etc/issue | cut -b 1-6)"
			if [ "Ubuntu" = "$VER" ]; then
				SYSTEM="Ubuntu"
			else
				SYSTEM="$(cat /etc/debian_version)"
			fi
		fi
	elif [ "$SYSTEM" = "HP-UX" ] ; then
		MOD=$(uname -m)
		SYSTEM="HPUX"
		ITAN="ITANIUM"
		RISC="PARISC"
		if [ "$MOD" = "ia64" ] ; then
			OS="$SYSTEM"
			PROCESSOR="$ITAN$(uname -m | sed 's/\//_/g')"
		else
			OS="$SYSTEM"
			PROCESSOR="$RISC$(uname -m | sed 's/\//_/g')"
		fi	

	fi
	export $PROCESSOR	
}