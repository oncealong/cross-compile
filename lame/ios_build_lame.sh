#!/bin/bash
set -x
CURRENT_DIR=$(pwd)
LAME_SRC=lame-3.100
LAME_BUILD_OUTPUT=$CURRENT_DIR/build/iOS
mkdir -p $LAME_BUILD_OUTPUT
echo "-------"
echo "lame out put dir=$LAME_BUILD_OUTPUT"
echo "-------"

cd $LAME_SRC

./configure \
--disable-shared \
--disable-frontend \
--host=arm-apple-darwin \
--prefix=$LAME_BUILD_OUTPUT \
CC="xcrun -sdk iphoneos clang -arch armv7" \
CFLAGS="-arch armv7 -fembed-bitcode -miphoneos-version-min=7.0" \
LDLAGS="-arch armv7 -fembed-bitcode -miphoneos-version-min=7.0"

make clean
make -j8
make install

set +x