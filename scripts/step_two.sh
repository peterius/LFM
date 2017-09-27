#!/bin/sh

if [ $UID == 0 ]; then
	echo "No need to run this as root"
	exit
fi

mkdir -p system
SYSROOT=`readlink -f ./system`
cd tools/ftinstall
make
cd ../../
FTINSTALL=`readlink -f ./tools/ftinstall/ftinstall`
PATCHDIR=`readlink -f ./patches`

# as long as toolchain is in the path first, --host=aarch64-linux-gnu will find the right binaries
export PATH=~/projects/LFM/toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin:$PATH
export ARCH=arm64
export CROSS_COMPILE=~/projects/LFM/toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
#source ./cross_compile_env.sh

#kernel headers
if ! [ -e system/usr/include/linux/unistd.h ] ; then
	mkdir -p system/usr/include 
	cd linux-4.13.2
	make INSTALL_HDR_PATH=../tmp headers_install
	cd ..
	cp -rv tmp/include/* system/usr/include/
fi

# FIXME what about pgp signatures ?

mkdir -p system/etc
cp ./etc/passwd $SYSROOT/etc/passwd
cp ./etc/group $SYSROOT/etc/group

#glibc
if ! [ -e system/bin/locale ] ; then
	if ! [ -e glibc-2.26 ] ; then
		if ! [ -e glibc-2.26.tar.xz ] ; then
			if ! [ `curl -O ftp.gnu.org/gnu/glibc/glibc-2.26.tar.xz` ] ; then
				echo "Can't get glibc source"
				exit
			fi
		fi
		tar xJvf glibc-2.26.tar.xz
	fi
	mkdir -p system/lib
	mkdir -p system/sbin
	mkdir -p system/bin
	mkdir -p system/share
	mkdir -p system/libexec
	mkdir -p system/var/db
	mkdir -p system/local
	cd glibc-2.26
	mkdir -p build
	cd build
	# what about a --prefix-local ? FIXME
	../configure --host=aarch64-linux-gnu --enable-kernel=3.2 \
			--with-headers=$SYSROOT/usr/include --prefix=
	make -j4
	$FTINSTALL $SYSROOT make install
	cd ../../
fi

#export LDFLAGS=-L$SYSROOT/lib/
export LD_LIBRARY_PATH=$SYSROOT/lib
export LD_INCLUDE_PATH=$SYSROOT/include
export INCLUDES="-I$SYSROOT/include $INCLUDES"

if ! [ -e system/sbin/init ] ; then
	if ! [ -e sysvinit-2.88dsf ] ; then
		if ! [ -e sysvinit-2.88dsf.tar.bz2 ] ; then
			if [ `curl -L -O http://download.savannah.gnu.org/releases/sysvinit/sysvinit-2.88dsf.tar.bz2` ] ; then
				echo "Can't get sysvinit source"
				rm sysvinit-2.88dsf.tar.bz2
				exit
			fi
		fi
		tar xjvf sysvinit-2.88dsf.tar.bz2 || `rm sysvinit-2.88dsf.tar.gz2; exit`
	fi
	cd sysvinit-2.88dsf
	make -C src clobber
	make -C src CC="${CROSS_COMPILE}gcc"
	make -C src ROOT=$SYSROOT install
	#$FTINSTALL make install
	cd ../../
fi

if ! [ -e system/bin/cp ] ; then
	if ! [ -e coreutils-8.27 ] ; then
		if ! [ -e coreutils-8.27.tar.xz ] ; then
			if ! [ `curl -O ftp.gnu.org/gnu/coreutils/coreutils-8.27.tar.xz` ] ; then
				echo "Can't get coreutils source"
				exit
			fi
		fi
		tar xJvf coreutils-8.27.tar.xz
	fi
	cd coreutils-8.27
	patch configure < $PATCHDIR/coreutils-8.27-no-perl.patch
	#patch build-aux/install-sh < ../coreutils-8.27-install-bash.patch
	#patch po/Makefile.in.in < ../coreutils-8.27-po-install-bash.patch
	mkdir -p build
	cd build
	echo "fu_cv_sys_stat_statfs2_bsize=yes" > config.cache
	echo "gl_cv_func_working_mkstemp=yes" >> config.cache
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu \
		--enable-install-program=hostname \
		--cache-file=config.cache
	make -j4
	$FTINSTALL $SYSROOT make install
	cd ../../
fi

if ! [ -e system/bin/bash ] ; then
	if ! [ -e bash-4.4 ] ; then
		if ! [ -e bash-4.4.tar.gz ] ; then
			if [ `curl -O ftp.gnu.org/gnu/bash/bash-4.4.tar.gz` ] ; then
				echo "Can't get bash source"
				exit
			fi
		fi
		tar xzvf bash-4.4.tar.gz 
	fi
	cd bash-4.4 
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu
	make -j4
	$FTINSTALL $SYSROOT make install
	cd ../../
fi

if ! [ -e system/bin/wall ] ; then
	if ! [ -e util-linux-2.30.2 ] ; then
		if ! [ -e util-linux-2.30.2.tar.gz ] ; then
			if [ `curl -O https://www.kernel.org/pub/linux/utils/util-linux/v2.30/util-linux-2.30.2.tar.gz` ] ; then
				echo "Can't get util-linux source"
				exit
			fi
		fi
		tar xzvf util-linux-2.30.2.tar.gz 
	fi
	cd util-linux-2.30.2 
	patch Makefile.in < $PATCHDIR/util-linux-2.30.2-nochgrp.patch  
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu --without-python
	make -j4
	$FTINSTALL $SYSROOT make install
	cd ../../
fi

# FIXME make sure this is necessary, this is a weird one:
#chmod 644 $SYSROOT/include/gnu/stubs.h

if ! [ -e system/bin/saxda ] ; then
	if ! [ -e eudev-3.2.4 ] ; then
		if ! [ -e eudev-3.2.4.tar.gz ] ; then
			if [ `curl -O http://dev.gentoo.org/~blueness/eudev/eudev-3.2.4.tar.gz` ] ; then
				echo "Can't get eudev source"
				exit
			fi
		fi
		tar xzvf eudev-3.2.4.tar.gz 
	fi
	cd eudev-3.2.4 
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu
	make -j4
	$FTINSTALL $SYSROOT make install
	cd ../../
fi

exit
#make sure "build" is clean... what about cleaning this? ?!?!

if [  1 ];  then
	if curl -O ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz ; then
		tar xzvf ncurses-6.0.tar.gz
	else
		echo "Can't get ncurses source"
		exit
	fi
	cd ncurses-6.0
	./configure --help
fi
