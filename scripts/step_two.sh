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

TOOLCHAINDIR=`readlink -f ./toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu`

# as long as toolchain is in the path first, --host=aarch64-linux-gnu will find the right binaries
export PATH=$TOOLCHAINDIR/bin:$PATH
export ARCH=arm64
export CROSS_COMPILE=$TOOLCHAINDIR/bin/aarch64-linux-gnu-
#source ./cross_compile_env.sh
export TOOLCHAIN=$CROSSCOMPILE

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
	# in case of stale
	rm $SYSROOT/lib/libc.so.bak
	cd glibc-2.26
	mkdir -p build
	cd build
	# what about a --prefix-local ? FIXME
	../configure --host=aarch64-linux-gnu --enable-kernel=3.2 \
			--with-tls --with-__thread \
			--with-headers=$SYSROOT/usr/include --prefix= || die "Can't configure glibc"
	make -j4 || die "Can't compile glibc"
	$FTINSTALL $SYSROOT make install || die "Can't install glibc"
	cd ../../
	# replace sysroot ld scripts with actual root, for building against
	scripts/unchroot_chroot_ld_scripts.sh
fi
export LDFLAGS="-Wl,--sysroot=$SYSROOT -Wl,--hash-style=gnu -Wl,-dynamic-linker=$SYSROOT/lib/ld-linux-aarch64.so.1 -L$SYSROOT/lib -L$SYSROOT/usr/lib"
export CFLAGS="-Wl,--sysroot=$SYSROOT -Wl,--hash-style=gnu -Wl,-dynamic-linker=$SYSROOT/lib/ld-linux-aarch64.so.1 -L$SYSROOT/lib -L$SYSROOT/usr/lib -I$SYSROOT/include -I$SYSROOT/usr/include "
# __GNU_LIBRARY_ is for 

export LD_LIBRARY_PATH=$SYSROOT/lib:$SYSROOT/usr/lib
export LD_INCLUDE_PATH=$SYSROOT/include
export SYSROOT=$SYSROOT
export V=1

mkdir -p system/usr/bin
mkdir -p system/usr/lib
#gcc is necessary for libstdc++
#but we're just going to copy it from linaro toolchain and hope it works
#because cross compiling is apparently such a nightmare
if ! [ -e filethatdoesntexist ] ; then
if ! [ -e system/usr/lib/libgmp.so ] ; then
	if ! [ -e gmp-6.1.2 ] ; then
		if ! [ -e gmp-6.1.2.tar.xz ] ; then
			`curl -O ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz` || \
				die "Can't get gmp source"
		fi
		tar xJvf gmp-6.1.2.tar.xz
	fi
	cd gmp-6.1.2 
	mkdir -p build
	cd build
	../configure --host=aarch64-linux-gnu \
			--with-sysroot=$SYSROOT \
			--prefix=/usr || die "Can't configure gmp"
	make -j4 || die "Can't compile gmp"
	$FTINSTALL $SYSROOT make install || die "Can't install gmp"
	cd ../../
fi
if ! [ -e system/usr/lib/libmpfr.so ] ; then
	if ! [ -e mpfr-3.1.6 ] ; then
		if ! [ -e mpfr-3.1.6.tar.xz ] ; then
			`curl -O ftp.gnu.org/gnu/mpfr/mpfr-3.1.6.tar.xz` || \
				die "Can't get mpfr source"
		fi
		tar xJvf mpfr-3.1.6.tar.xz
	fi
	cd mpfr-3.1.6 
	mkdir -p build
	cd build
	../configure --host=aarch64-linux-gnu \
			--with-sysroot=$SYSROOT \
			--with-gmp-prefix=/usr \
			--prefix=/usr || die "Can't configure mpfr"
	make -j4 || die "Can't compile mpfr"
	$FTINSTALL $SYSROOT make install || die "Can't install mpfr"
	cd ../../
fi
if ! [ -e system/usr/lib/libmpc.so ] ; then
	if ! [ -e mpc-1.0.3 ] ; then
		if ! [ -e mpc-1.0.3.tar.gz ] ; then
			`curl -O ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz` || \
				die "Can't get mpc source"
		fi
		tar xzvf mpc-1.0.3.tar.gz
	fi
	cd mpc-1.0.3 
	mkdir -p build
	cd build
	../configure --host=aarch64-linux-gnu \
			--with-sysroot=$SYSROOT \
			--with-gmp-prefix=/usr \
			--prefix=/usr || die "Can't configure mpc"
	make -j4 || die "Can't compile mpc"
	$FTINSTALL $SYSROOT make install || die "Can't install mpc"
	cd ../../
fi
if ! [ -e system/usr/lib/libisl.so ] ; then
	if ! [ -e isl-0.18 ] ; then
		if ! [ -e isl-0.18.tar.bz2 ] ; then
			`curl -O ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2` || \
				die "Can't get isl source"
		fi
		tar xjvf isl-0.18.tar.bz2 
	fi
	cd isl-0.18 
	# a little unsure about this, the -lgmp looks duplicated some places FIXME
	patch Makefile.in < $PATCHDIR/isl-0.18-includes-and-lgmp.patch
	mkdir -p build
	cd build
	../configure --host=aarch64-linux-gnu \
			--with-sysroot=$SYSROOT \
			--with-gmp-prefix=/usr \
			--prefix=/usr || die "Can't configure isl"
	make -j4 || die "Can't compile isl"
	$FTINSTALL $SYSROOT make install || die "Can't install isl"
	cd ../../
fi
export CFLAGS=""
export LDFLAGS=""
#export CFLAGS="-Wl,--sysroot=$SYSROOT -Wl,--hash-style=gnu -Wl,-dynamic-linker=$SYSROOT/lib/ld-linux-aarch64.so.1 -L$SYSROOT/lib -L$SYSROOT/usr/lib -I$SYSROOT/../gcc-7.2.0/include -I$SYSROOT/include -I$SYSROOT/usr/include"
#export CFLAGS="-Wl,--sysroot=$SYSROOT -Wl,--hash-style=gnu -L$SYSROOT/lib -L$SYSROOT/usr/lib -I$SYSROOT/../gcc-7.2.0/include -I$SYSROOT/include -I$SYSROOT/usr/include"
#export CFLAGS="-Wl,--sysroot=$SYSROOT -I$SYSROOT/../gcc-7.2.0/include -I$SYSROOT/include -I$SYSROOT/usr/include"
#export CFLAGS="-Wl,--sysroot=$SYSROOT"
#export CC="$CROSS_COMPILE"gcc
#export CC_FOR_TARGET="$CROSS_COMPILE"gcc
#export GCC_FOR_TARGET="$CROSS_COMPILE"gcc
#export CXX_FOR_TARGET="$CROSS_COMPILE"g++
#export AR_FOR_TARGET="$CROSS_COMPILE"ar
#export AS_FOR_TARGET="$CROSS_COMPILE"as
#export NM_FOR_TARGET="$CROSS_COMPILE"nm
#export LD_FOR_TARGET="$CROSS_COMPILE"ld
#export STRIP_FOR_TARGET='"$CROSS_COMPILE"strip'
#export RANLIB_FOR_TARGET="$CROSS_COMPILE"ranlib
#export READELF_FOR_TARGET="$CROSS_COMPILE"readelf
#export OBJCOPY_FOR_TARGET="$CROSS_COMPILE"objcopy
#export OBJDUMP_FOR_TARGET="$CROSS_COMPILE"objdump
if [ -e system/usr/bin/gcc ] ; then
	if ! [ -e gcc-7.2.0 ] ; then
		if ! [ -e gcc-7.2.0.tar.xz ] ; then
			if ! `curl -O ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.xz` ; then
				die "Can't get gcc source"
			fi
		fi
		tar xJf gcc-7.2.0.tar.xz
	fi
	cd gcc-7.2.0 
	#patch gcc/Makefile.in < $PATCHDIR/gcc-7.2.0-no-selftest.patch
	#patch libgcc/config.host < $PATCHDIR/gcc-7.2.0-no-softfp.patch
	#patch libgcc/soft-fp/half.h < $PATCHDIR/gcc-7.2.0-half-HFType.patch
	#patch libstdc++-v3/include/bits/move.h < $PATCHDIR/gcc-7.2.0-builtin_addressof.patch
	#patch libstdc++-v3/include/std/type_traits < $PATCHDIR/gcc-7.2.0-type_traits.patch
	#patch libstdc++-v3/libsupc++/new < $PATCHDIR/gcc-7.2.0-align_val_t.patch
	# really unsure about this one... maybe something unnecessary
	# and this should have worked... 
	#patch libstdc++-v3/libsupc++/new < $PATCHDIR/gcc-7.2.0-new.patch
	#patch gcc/Makefile.in < $PATCHDIR/gcc-7.2.0-toolchain-use.patch
	#patch libgcc/Makefile.in < $PATCHDIR/gcc-7.2.0-toolchain-use-libgcc.patch
	mkdir -p build
	cd build
	#../configure --host=aarch64-linux-gnu \
	../configure --target=aarch64-linux-gnu \
			--enable-languages=c,c++ --enable-__cxa_atexit --enable-c99 --enable-long-long \
			--enable-threads=posix \
			--with-mpfr=$SYSROOT/usr --with-mpc=$SYSROOT/usr --with-gmp=$SYSROOT/usr \
			--with-sysroot=$SYSROOT \
			--prefix=/usr || die "Can't configure gcc"
	make -j4 || die "Can't compile gcc"
	$FTINSTALL $SYSROOT make install || die "Can't install gcc"
	cd ../../
fi
# skipping gcc and friends...
fi
cp $TOOLCHAINDIR/aarch64-linux-gnu/libc/lib/libstdc++.so.6.0.22 $SYSROOT/lib/
cp $TOOLCHAINDIR/aarch64-linux-gnu/libc/lib/libgcc_s.so.1 $SYSROOT/lib/
cd $SYSROOT/lib
ln -s libstdc++.so.6.0.22 libstdc++.so.6
ln -s libstdc++.so.6.0.22 libstdc++.so
ln -s libgcc_s.so.1 libgcc_s.so
cd ../../

#export LDFLAGS=-L$SYSROOT/lib/
# consider removing... I think this was just for coreutil and it's not always first
# we could maybe attach it to $(CC), this is kind of ridiculous
#export INCLUDES="-I$SYSROOT/include $INCLUDES"

#gcc needs to see its own includes first so as not to load the SYSROOT obstack.h
export CFLAGS="-Wl,--hash-style=gnu -Wl,--sysroot=$SYSROOT -L$SYSROOT/lib -I$SYSROOT/include -DO_BINARY=0 -DO_TEXT=0"
#export LDFLAGS="-Wl,--hash-style=gnu -L$SYSROOT/lib"
#export CC=$(CROSS_COMPILE)gcc
if ! [ -e system/sbin/init ] ; then
	if ! [ -e sysvinit-2.88dsf ] ; then
		if ! [ -e sysvinit-2.88dsf.tar.bz2 ] ; then
			`curl -L -O http://download.savannah.gnu.org/releases/sysvinit/sysvinit-2.88dsf.tar.bz2` || \
				die "Can't get sysvinit source"
		fi
		tar xjvf sysvinit-2.88dsf.tar.bz2 || `rm sysvinit-2.88dsf.tar.gz2; exit`
	fi
	cd sysvinit-2.88dsf
	make -C src clobber
	make -C src CC="${CROSS_COMPILE}gcc" || die "Can't compile sysvinit"
	make -C src ROOT=$SYSROOT install || die "Can't install sysvinit"
	#$FTINSTALL make install
	cd ../
fi

# the corelibs gnulib_tests should figure out there's no O_BINARY or O_TEXT, maybe in
# the configure?  but it doesn't somehow
if ! [ -e system/bin/cp ] ; then
	if ! [ -e coreutils-8.27 ] ; then
		if ! [ -e coreutils-8.27.tar.xz ] ; then
			`curl -O ftp.gnu.org/gnu/coreutils/coreutils-8.27.tar.xz` || \
				die "Can't get coreutils source"
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
			`curl -O ftp.gnu.org/gnu/bash/bash-4.4.tar.gz` || \
				die "Can't get bash source"
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

# util-linux really needs ncurses and pam
if ! [ -e system/usr/lib/libncurses.a ] ; then
	if ! [ -e ncurses-6.0 ] ; then
		if ! [ -e ncurses-6.0.tar.gz ] ; then
			`curl -O ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz` || \
				die "Can't get ncurses source"
		fi
		tar xzvf ncurses-6.0.tar.gz 
	fi
	cd ncurses-6.0 
	mkdir -p build
	cd build
	export V=1
	# what about --with-shared ??
	../configure --prefix=/usr --host=aarch64-linux-gnu || die "Can't configure ncurses"
	make -j4 || die "Can't compile ncurses"
	$FTINSTALL $SYSROOT make install || die "Can't install ncurses"
	cd ../../
fi

# util-linux prlimit unshare setns definition conflicts with our system includes... 
# configure script apparently can't figure out that we have these functions?  or do we?
export CFLAGS="-Wl,--hash-style=gnu -Wl,--sysroot=$SYSROOT -L$SYSROOT/lib -I$SYSROOT/include -DHAVE_PRLIMIT -DHAVE_UNSHARE -DHAVE_SETNS"
export LDFLAGS="-Wl,-rpath=$SYSROOT/lib"
if ! [ -e system/bin/wall ] ; then
	if ! [ -e util-linux-2.30.2 ] ; then
		if ! [ -e util-linux-2.30.2.tar.gz ] ; then
			`curl -O https://www.kernel.org/pub/linux/utils/util-linux/v2.30/util-linux-2.30.2.tar.gz` || \
				die "Can't get util-linux source"
		fi
		tar xzvf util-linux-2.30.2.tar.gz 
	fi
	cd util-linux-2.30.2 
	patch Makefile.in < $PATCHDIR/util-linux-2.30.2-nochgrp.patch  
	patch sys-utils/fallocate.c < $PATCHDIR/util-linux-2.30.2-fallocate.patch
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu --without-python || die "Can't configure util-linux"
	make -j4 || die "Can't compile util-linux"
	$FTINSTALL $SYSROOT make install || die "Can't install util-linux"
	cd ../../
fi

#CFLAGS="-fPIC"
LDFLAGS="-Wl,-rpath=$SYSROOT/lib -L$SYSROOT/lib -lpthread-2.26"
if ! [ -e system/lib/liblzma.so ] ; then
	if ! [ -e xz-5.2.3 ] ; then
		if ! [ -e xz-5.2.3.tar.bz2 ] ; then
			`curl -L -O https://tukaani.org/xz/xz-5.2.3.tar.bz2` || \
				die "Can't get xz source"
		fi
		tar xjvf xz-5.2.3.tar.bz2 
	fi
	cd xz-5.2.3 
	mkdir -p build
	cd build
	export V=1
	../configure --prefix=/usr --host=aarch64-linux-gnu --with-pic || die "Can't configure xz" 
	make -j4 || die "Can't compile xz"
	$FTINSTALL $SYSROOT make install || die "Can't install xz"
	cd ../../
fi

# just for you zlib:
export CROSS_PREFIX=~/projects/LFM/toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
if ! [ -e system/lib/libz.so ] ; then
	if ! [ -e zlib-1.2.11 ] ; then
		if ! [ -e zlib-1.2.11.tar.xz ] ; then
			`curl -L -O http://zlib.net/zlib-1.2.11.tar.xz` || \
				die "Can't get zlib source"
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

export LDFLAGS="-L$SYSROOT/lib -L$SYSROOT/usr/lib"

if ! [ -e system/lib/libkmod.so ] ; then
	if ! [ -e kmod-24 ] ; then
		if ! [ -e kmod-24.tar.xz ] ; then
			`curl -O https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-24.tar.xz` || \
				die "Can't get kmod source"
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

# remove unnecessary libtool archive
rm $SYSROOT/lib/libuuid.la
rm $SYSROOT/lib/libblkid.la

#export LD_LIBRARY_PATH="$SYSROOT/lib $SYSROOT/usr/lib"
export LDFLAGS="-Wl,-rpath=$SYSROOT/lib -Wl,-rpath-link=$SYSROOT/lib -L$SYSROOT/lib"
#export LT_SYS_LIBRARY_PATH="$SYSROOT/lib $SYSROOT/usr/lib"
export PKG_CONFIG_LIBDIR="$SYSROOT/lib $SYSROOT/usr/lib"
export BLKID_CFLAGS="-I$SYSROOT/include -I$SYSROOT/usr/include"
export BLKID_LIBS="-Wl,-rpath,$SYSROOT/lib -L$SYSROOT/lib -L$SYSROOT/usr/lib"

if ! [ -e system/sbin/udevd ] ; then
	if ! [ -e eudev-3.2.4 ] ; then
		if ! [ -e eudev-3.2.4.tar.gz ] ; then
			`curl -O http://dev.gentoo.org/~blueness/eudev/eudev-3.2.4.tar.gz` || \
				die "Can't get eudev source"
		fi
		tar xzvf eudev-3.2.4.tar.gz 
	fi
	cd eudev-3.2.4 
	patch src/shared/util.c < $PATCHDIR/eudev-3.2.4-constbasename.patch
	patch src/udev/Makefile.in < $PATCHDIR/eudev-3.2.4-udevcoreblkid.patch
	#patch configure < ../patches/eudev-3.2.4-configlibtool.patch
	mkdir -p build
	cd build
	export V=1
	../configure --prefix= --host=aarch64-linux-gnu || die "Can't configure eudev"
	make -j4 || die "Can't compile eudev"
	$FTINSTALL $SYSROOT make install || die "Can't install eudev"
	cd ../../
fi

exit
