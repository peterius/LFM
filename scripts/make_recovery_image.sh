#!/bin/bash

if [ $# != 3 ]; then
	echo "./make_recovery_img.sh [kernel] [ramdisk] [output]"
	exit
fi

KERNEL=$1
RAMDISKDIR=$2
OUTPUT=$3
OURDIR=`pwd`

#Xiaomi Redmi Note 4 (mido)
PAGESIZE=2048
#KERNEL_COMMANDLINE="console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci earlycon=msm_hsl_uart,0x78af000 androidboot.selinux=permissive"
# something checks for permissive and won't boot without it
#KERNEL_COMMANDLINE="console=tty0 androidboot.selinux=permissive ehci-hcd.park=3 lpm_levels.sleep_disabled=1 "
#KERNEL_COMMANDLINE="console=tty0,115200 no_console_suspend=1 androidboot.selinux=permissive ehci-hcd.park=3 lpm_levels.sleep_disabled=1 "
KERNEL_COMMANDLINE="unused... we're forcing command line in kernel"

cd $RAMDISKDIR
find ./ -print | cpio -o -H newc | gzip -9 > $OURDIR/newramdisk.gz

cd $OURDIR

android/mkbootimg/mkbootimg --kernel $KERNEL --ramdisk newramdisk.gz --pagesize $PAGESIZE --cmdline "$KERNEL_COMMANDLINE" -o $OUTPUT
