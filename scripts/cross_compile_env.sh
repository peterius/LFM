#!/bin/sh

if [ $UID == 0 ]; then
	echo "No need to run this as root"
	exit
fi

# FIXME the relative links !?!?!?

LFMROOT=`readlink -f ./`
SYSROOT=`readlink -f ./system`
# as long as toolchain is in the path first, --host=aarch64-linux-gnu will find the right binaries
export PATH=$LFMROOT/toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin:$PATH
export ARCH=arm64
export CROSS_COMPILE=$LFMROOT/toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
export CFLAGS="-I$SYSROOT/include -I$SYSROOT/usr/include"
export LDFLAGS="-L$SYSROOT/lib -L$SYSROOT/usr/lib"

# okay... so this is great for our stuff... but configure scripts are dying because they can't find /lib/ld... 

FTINSTALL=`readlink -f ./tools/ftinstall/ftinstall`

