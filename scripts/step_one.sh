#!/bin/sh

if [ $UID == 0 ] ; then
	echo "No need to run as root"
	exit
fi

git clone https://github.com/MiCode/Xiaomi_Kernel_OpenSource
echo "Downloading and extracting linux kernel..."
curl http://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.13.2.tar.xz > linux-4.13.2.tar.xz
tar xJvf linux-4.13.2.tar.xz 
ln -sf Xiaomi_Kernel_OpenSource kernel

mkdir -p toolchain

echo "Downloading and extracting linaro toolchain..."
LINARO_SITE=https://releases.linaro.org/components/toolchain/binaries/latest/aarch64-linux-gnu/
LINARO=gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu
if curl -L -O $LINARO_SITE$LINARO.tar.xz ; then
cd toolchain; tar xJvf ../$LINARO.tar.xz 
fi

echo "Compile kernel"
