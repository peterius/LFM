#!/bin/bash

if [ $# == 1 ] && [ $1 == "clean" ]; then
	echo "Cleaning..."
	# should probably have a list of packages with dependencies... but...
	# fine for early system stuff which won't really change
	# FIXME we could just have a list of names and links and then the downloader stuff
	# would be the same... 
	cd tools
	make clean
	cd ..
	rm -rf system
	rm -rf glibc-2.26/build
	rm -rf gmp-6.1.2/build
	rm -rf mpfr-3.1.6/build
	rm -rf mpc-1.0.3/build
	rm -rf isl-0.18/build
	rm -rf gcc-7.2.0/build
	rm -rf bash-4.4/build
	rm -rf coreutils-8.27/build
	rm -rf util-linux-2.30.2/build
	rm -rf sysvinit-2.88dsf
	rm -rf xz-5.2.3/build
	rm -rf zlib-1.2.11
	rm -rf kmod-24/build
	rm -rf eudev-3.2.4/build
	exit
elif [ $# == 1 ] && [ $1 == "distclean" ]; then
	echo "Cleaning completely..."
	cd tools
	make clean
	cd ..
	rm -rf system
	rm -rf glibc-2.26
	rm -rf gmp-6.1.2
	rm -rf mpfr-3.1.6
	rm -rf mpc-1.0.3
	rm -rf isl-0.18
	rm -rf gcc-7.2.0
	rm -rf bash-4.4
	rm -rf coreutils-8.27
	rm -rf util-linux-2.30.2
	rm -rf sysvinit-2.88dsf
	rm -rf xz-5.2.3
	rm -rf zlib-1.2.11
	rm -rf kmod-24
	rm -rf eudev-3.2.4
	exit
fi
#git submodule init
#git submodule update

#scripts/step_one.sh
scripts/step_two.sh
#scripts/step_three.sh
