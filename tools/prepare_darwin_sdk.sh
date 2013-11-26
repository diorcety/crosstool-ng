#!/bin/sh

function usage {
	echo "Usage: $0 sdk"; exit 1;
}

if [ "$#" == "0" ]; then
	usage
fi

SDK_PATH=$1
find $SDK_PATH -type d -exec chmod u+w {} \;
ln -s i686-apple-darwin10 $SDK_PATH/usr/lib/x86_64-apple-darwin10
ln -s i686-apple-darwin10 $SDK_PATH/usr/lib/gcc/x86_64-apple-darwin10
ln -s ../i686-apple-darwin10 $SDK_PATH/usr/include/c++/4.2.1/x86_64-apple-darwin10/i386
ln -s ../i686-apple-darwin9 $SDK_PATH/usr/include/c++/4.2.1/x86_64-apple-darwin9/i386
ln -s ../i686-apple-darwin10 $SDK_PATH/usr/include/c++/4.0.0/x86_64-apple-darwin10/i386
ln -s ../i686-apple-darwin9 $SDK_PATH/usr/include/c++/4.0.0/x86_64-apple-darwin9/i386
find $SDK_PATH -exec chmod a-w {} \;
