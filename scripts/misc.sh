#!/bin/sh

if [ $UID == 0 ]; then
	echo "No need to run this as root"
	exit
fi

die()
{
	echo $1
	exit
}

source scripts/cross_compile_env.sh
LDFLAGS=""

if ! [ -e system/usr/bin/strace ] ; then
	if ! [ -e strace ]; then
		git clone https://github.com/strace/strace.git
	fi
	cd strace
	git checkout tags/v4.19
	if ! [ -e configure ]; then
		./bootstrap
	fi
	./configure --host=aarch64-linux-gnu \
		--prefix=/usr || die "Can't configure strace"
	# chokes on cross compile... 
	make -j4 || die "Can't compile strace"
	$FTINSTALL $SYSROOT make install || die "Can't install strace"
	cd ../
fi
	
