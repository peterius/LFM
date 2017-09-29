#!/bin/sh

if [ $UID == 0 ]; then
	echo "No need to run this as root"
	exit
fi

SYSROOT=`readlink -f ./system`
# as long as toolchain is in the path first, --host=aarch64-linux-gnu will find the right binaries
export PATH=~/projects/LFM/toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin:$PATH
export ARCH=arm64
export CROSS_COMPILE=~/projects/LFM/toolchain/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
#source ./cross_compile_env.sh

cd lfmb
make
cp lfmbd $SYROOT/sbin/lfmbd
cd ../

find $SYSROOT/{,usr/}{bin,lib,sbin} -type f -exec $CROSS_COMPILE'strip' --strip-debug '{}' ';'

#restore libc/libpthread ld scripts
scripts/unchroot_chroot_ld_scripts.sh

mkdir -p $SYSROOT/etc/init.d

touch $SYSROOT/var/log/{btmp,lastlog,wtmp}

# permissions, probably have to be root for this, FIXME

chgrp -v utmp $SYSROOT/var/log/lastlog
chmod -v 664 $SYSROOT/var/log/lastlog
chmod -v 600 $SYSROOT/var/log/btmp

chown -Rv 0:0 $SYSROOT

#util-linux-2.30.2
# FIXME FIXME verify these are right, these are setgid now right?
chgrp tty $SYSROOT/bin/wall
chmod g+s $SYSROOT/bin/wall
chgrp tty $SYSROOT/bin/write
chmod g+s $SYSROOT/bin/write

chown 0:0 $SYSROOT/sbin/lfmbd		#FIXME lots of chowns... 
chmod 700 $SYSROOT/sbin/lfmbd

# ln -sv bash /bin/sh

