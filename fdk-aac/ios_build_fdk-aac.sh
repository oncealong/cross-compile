#!/bin/bash
set -x

# directories
CURRENT_DIR=$(pwd)
# must be an absolute path
FDKAAC_BUILD_OUTPUT=$CURRENT_DIR/build/iOS
FAT_LIB_OUTPUT="$FDKAAC_BUILD_OUTPUT/fdk-aac-ios"
SCRATCH="scratch"
FDKAAC_SRC=$CURRENT_DIR/fdk-aac-2.0.0
GAS_PREPROCESSOR=$CURRENT_DIR/extras
mkdir -p $FDKAAC_BUILD_OUTPUT

echo "fdkaac src dir=$FDKAAC_SRC"
echo "fdkaac out put dir=$FDKAAC_BUILD_OUTPUT"

cd $FDKAAC_SRC
if [ ! -d "$FDKAAC_SRC/configure" ]; then
    ./autogen.sh
fi

CONFIGURE_FLAGS="--enable-static --with-pic=yes --disable-shared"

ARCHS="arm64 x86_64 i386 armv7"

COMPILE="y"
LIPO="y"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CPU=
		    if [ "$ARCH" = "x86_64" ]
		    then
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
			HOST="--host=x86_64-apple-darwin"
		    else
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
			HOST="--host=i386-apple-darwin"
		    fi
		else
		    PLATFORM="iPhoneOS"
		    if [ $ARCH = arm64 ]
		    then
		        HOST="--host=aarch64-apple-darwin"
                    else
		        HOST="--host=arm-apple-darwin"
	            fi
		    CFLAGS="$CFLAGS -fembed-bitcode"
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang -Wno-error=unused-command-line-argument-hard-error-in-future"
		AS="$GAS_PREPROCESSOR/gas-preprocessor.pl $CC"
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		$FDKAAC_SRC/configure \
		    $CONFIGURE_FLAGS \
		    $HOST \
		    $CPU \
		    CC="$CC" \
		    CXX="$CC" \
		    CPP="$CC -E" \
        AS="$AS" \
		    CFLAGS="$CFLAGS" \
		    LDFLAGS="$LDFLAGS" \
		    CPPFLAGS="$CFLAGS" \
		    --prefix="$FDKAAC_BUILD_OUTPUT/$ARCH"

		make -j3
    make install
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT_LIB_OUTPUT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $FDKAAC_BUILD_OUTPUT/$1/lib
	for LIB in *.a
	do
		cd $CWD
		lipo -create `find $FDKAAC_BUILD_OUTPUT -name $LIB` -output $FAT_LIB_OUTPUT/lib/$LIB
	done

	cd $CWD
	cp -rf $FDKAAC_BUILD_OUTPUT/$1/include $FAT_LIB_OUTPUT
fi
set +x