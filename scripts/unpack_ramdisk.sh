#!/bin/bash

if [ $# != 1 ]; then
	echo "./unpack_ramdisk [ramdisk.gz]"
	exit
fi

if [[ $1 =~ (.*)\.gz ]]; then
	DIR=${BASH_REMATCH[1]}
	mkdir -p $DIR
	cd $DIR
	gzip -c -d ../$1 | cpio -i --make-directories
else
	echo "Doensn't end with .gz?"
fi
