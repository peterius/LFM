#!/bin/sh

if [ $UID == 0 ] ; then
	echo "No need to run as root"
	exit
fi

die()
{
	echo $1
	exit
}

#git clone https://github.com/MiCode/Xiaomi_Kernel_OpenSource
#ln -sf Xiaomi_Kernel_OpenSource kernel
echo "Linux kernel..."
if ! [ -e linux-4.13.2 ]; then
	if ! [ -e linux-4.13.2.tar.gz]; then
		echo "Downloading and extracting linux kernel..."
		if ! [ `curl http://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.13.2.tar.xz > linux-4.13.2.tar.xz`]; then
			die "Can't get linux source"
		fi
	fi
	tar xJvf linux-4.13.2.tar.xz 
fi


mkdir -p toolchain

echo "Linaro toolchain..."
LINARO_SITE=https://releases.linaro.org/components/toolchain/binaries/latest/aarch64-linux-gnu/
LINARO=gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
if ! [ -e toolchain/$LINARO ]; then
	echo "Downloading and extracting linaro toolchain..."
	if ! [ `curl -L -O $LINARO_SITE$LINARO.tar.xz` ] ; then
		die "Can't get linaro toolchain"
	fi
	cd toolchain; tar xJvf ../$LINARO.tar.xz 
fi

echo "Compile kernel"
echo "Ideally there should be a standard linux kernel and a .config for the particular phone"
echo "hardware.  Also any dts/dtsi files should be copied in and compiled in"
