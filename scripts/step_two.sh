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

mkdir -p system
SYSROOT=`readlink -f ./system`
cd tools/ftinstall
make || die "Can't make fake-chroot installer"
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
	make INSTALL_HDR_PATH=../tmp headers_install || die "Can't install linux kernel headers"
	cd ..
	cp -rv tmp/include/* system/usr/include/
	rm -rf tmp
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
				die "Can't get glibc source"
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
			--with-headers=$SYSROOT/usr/include --prefix= || die "Can't configure glibc"
	make -j4 || die "Can't compile glibc"
	$FTINSTALL $SYSROOT make install || die "Can't install glibc"
	cd ../../
fi

#export LDFLAGS=-L$SYSROOT/lib/
export LD_LIBRARY_PATH=$SYSROOT/lib
export LD_INCLUDE_PATH=$SYSROOT/include
# consider removing... I think this was just for coreutil and it's not always first
# we could maybe attach it to $(CC), this is kind of ridiculous
#export INCLUDES="-I$SYSROOT/include $INCLUDES"
# the corelibs gnulib_tests should figure out there's no O_BINARY or O_TEXT, maybe in
# the configure?  but it doesn't somehow
export CFLAGS="-I$SYSROOT/include -DO_BINARY=0 -DO_TEXT=0 $CFLAGS"
#export LDFLAGS="-L$SYSROOT/lib $LDFLAGS"

if ! [ -e system/sbin/init ] ; then
	if ! [ -e sysvinit-2.88dsf ] ; then
		if ! [ -e sysvinit-2.88dsf.tar.bz2 ] ; then
			if [ `curl -L -O http://download.savannah.gnu.org/releases/sysvinit/sysvinit-2.88dsf.tar.bz2` ] ; then
				die "Can't get sysvinit source"
			fi
		fi
		tar xjvf sysvinit-2.88dsf.tar.bz2 || `rm sysvinit-2.88dsf.tar.gz2; exit`
	fi
	cd sysvinit-2.88dsf
	make -C src clobber
	make -C src CC="${CROSS_COMPILE}gcc" || die "Can't compile sysvinit"
	make -C src ROOT=$SYSROOT install || die "Can't install sysvinit"
	#$FTINSTALL make install
	cd ../../
fi

if ! [ -e system/bin/cp ] ; then
	if ! [ -e coreutils-8.27 ] ; then
		if ! [ -e coreutils-8.27.tar.xz ] ; then
			if ! [ `curl -O ftp.gnu.org/gnu/coreutils/coreutils-8.27.tar.xz` ] ; then
				die "Can't get coreutils source"
			fi
		fi
		tar xJvf coreutils-8.27.tar.xz
	fi
	cd coreutils-8.27
	patch configure < $PATCHDIR/coreutils-8.27-no-perl.patch
	#patch Makefile.in < $PATCHDIR/coreutils-8.27-includes.patch
	mkdir -p build
	cd build
	rm config.cache # in case its stale
	echo "fu_cv_sys_stat_statfs2_bsize=yes" > config.cache
	echo "gl_cv_func_working_mkstemp=yes" >> config.cache
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu \
		--enable-install-program=hostname \
		--cache-file=config.cache || die "Can't configure coreutils"
	make -j4 || die "Can't compile coreutils"
	$FTINSTALL $SYSROOT make install || die "Can't install coreutils"
	cd ../../
fi

if ! [ -e system/bin/bash ] ; then
	if ! [ -e bash-4.4 ] ; then
		if ! [ -e bash-4.4.tar.gz ] ; then
			if [ `curl -O ftp.gnu.org/gnu/bash/bash-4.4.tar.gz` ] ; then
				die "Can't get bash source"
			fi
		fi
		tar xzvf bash-4.4.tar.gz 
	fi
	cd bash-4.4 
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu || die "Can't configure bash"
	make -j4 || die "Can't compile bash"
	$FTINSTALL $SYSROOT make install || die "Can't install bash"
	cd ../../
fi

if ! [ -e system/bin/wall ] ; then
	if ! [ -e util-linux-2.30.2 ] ; then
		if ! [ -e util-linux-2.30.2.tar.gz ] ; then
			if [ `curl -O https://www.kernel.org/pub/linux/utils/util-linux/v2.30/util-linux-2.30.2.tar.gz` ] ; then
				die "Can't get util-linux source"
			fi
		fi
		tar xzvf util-linux-2.30.2.tar.gz 
	fi
	cd util-linux-2.30.2 
	patch Makefile.in < $PATCHDIR/util-linux-2.30.2-nochgrp.patch  
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu --without-python || die "Can't configure util-linux"
	make -j4 || die "Can't compile util-linux"
	$FTINSTALL $SYSROOT make install || die "Can't install util-linux"
	cd ../../
fi

# FIXME make sure this is necessary, this is a weird one:
#chmod 644 $SYSROOT/include/gnu/stubs.h

if ! [ -e system/lib/liblzma.so ] ; then
	if ! [ -e xz-5.2.3 ] ; then
		if ! [ -e xz-5.2.3.tar.bz2 ] ; then
			if [ `curl -L -O https://tukaani.org/xz/xz-5.2.3.tar.bz2` ] ; then
				die "Can't get xz source"
			fi
		fi
		tar xjvf xz-5.2.3.tar.bz2 
	fi
	cd xz-5.2.3 
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu || die "Can't configure xz" 
	make -j4 || die "Can't compile xz"
	$FTINSTALL $SYSROOT make install || die "Can't install xz"
	cd ../../
fi

# just for you zlib:
export CROSS_PREFIX=~/projects/LFM/toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
if ! [ -e system/lib/libz.so ] ; then
	if ! [ -e zlib-1.2.11 ] ; then
		if ! [ -e zlib-1.2.11.tar.xz ] ; then
			if [ `curl -L -O http://zlib.net/zlib-1.2.11.tar.xz` ] ; then
				die "Can't get zlib source"
			fi
		fi
		tar xJvf zlib-1.2.11.tar.xz 
	fi
	cd zlib-1.2.11 
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= || die "Can't configure zlib" 
	make -j4 || die "Can't compile zlib"
	$FTINSTALL $SYSROOT make install || die "Can't install zlib"
	cd ../../
fi

if ! [ -e system/lib/libkmod.so ] ; then
	if ! [ -e kmod-24 ] ; then
		if ! [ -e kmod-24.tar.xz ] ; then
			if [ `curl -O https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-24.tar.xz` ] ; then
				die "Can't get kmod source"
			fi
		fi
		tar xJvf kmod-24.tar.xz 
	fi
	cd kmod-24 
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu \
			--with-xz --with-zlib  || die "Can't configure kmod"
	make -j4 || die "Can't compile kmod"
	$FTINSTALL $SYSROOT make install || die "Can't install kmod"
	cd ../../
fi

if ! [ -e $SYSROOT/include/bits/uio_lim.h ]; then
	echo "glibc apparently didn't install uio_lim.h, copying"
	cp glibc-2.26/bits/uio_lim.h $SYSROOT/include/bits/uio_lim.h
fi

if ! [ -e system/bin/saxda ] ; then
	if ! [ -e eudev-3.2.4 ] ; then
		if ! [ -e eudev-3.2.4.tar.gz ] ; then
			if [ `curl -O http://dev.gentoo.org/~blueness/eudev/eudev-3.2.4.tar.gz` ] ; then
				die "Can't get eudev source"
			fi
		fi
		tar xzvf eudev-3.2.4.tar.gz 
	fi
	cd eudev-3.2.4 
	patch src/shared/util.c < $PATCHDIR/eudev-3.2.4-constbasename.patch
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu || die "Can't configure eudev"
	make -j4 || die "Can't compile eudev"
	$FTINSTALL $SYSROOT make install || die "Can't install eudev"
	cd ../../
fi

exit
#make sure "build" is clean... what about cleaning this? ?!?!

if [  1 ];  then
	if curl -O ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz ; then
		tar xzvf ncurses-6.0.tar.gz
	else
		die "Can't get ncurses source"
	fi
	cd ncurses-6.0
	./configure --help
fi
