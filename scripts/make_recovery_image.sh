#!/bin/bash

if [ $# != 3 ]; then
	echo "./make_recovery_img.sh [kernel] [ramdisk] [output]"
	exit
fi

KERNEL=$1
RAMDISKDIR=$2
OUTPUT=$3
OURDIR=`pwd`

PAGESIZE=2048
#Xiaomi Redmi Note 4 (mido)
KERNEL_COMMANDLINE="console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci earlycon=msm_hsl_uart,0x78af000 androidboot.selinux=permissive"

cd $RAMDISKDIR
find ./ -print | cpio -o -H newc | gzip -9 > $OURDIR/newramdisk.gz

cd $OURDIR

android/mkbootimg/mkbootimg --kernel $KERNEL --ramdisk newramdisk.gz --pagesize $PAGESIZE --cmdline "$KERNEL_COMMANDLINE" -o $OUTPUT
