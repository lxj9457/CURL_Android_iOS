#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
    export CORES=$((`sysctl -n hw.logicalcpu`+1))
else
    export CORES=$((`nproc`+1))
fi

export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG

# curl common configuration arguments
# disable functionalities here to reduce size
ARGUMENTS=" \
    --with-pic \
    --disable-shared
    "

mkdir -p build/curl
cd curl
autoreconf -fi

# arm64
export TARGET_HOST=aarch64-linux-android
export ANDROID_ARCH=arm64-v8a
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
export SSL_DIR=$PWD/../openssl/build/$ANDROID_ARCH
export LDFLAGS="-L$PWD/../build/nghttp2/$ANDROID_ARCH/lib"

./configure --host=$TARGET_HOST \
            --target=$TARGET_HOST \
            --prefix=$PWD/build/$ANDROID_ARCH \
            --with-openssl=$SSL_DIR $ARGUMENTS \
            --disable-shared --enable-static \
            --with-nghttp2=$PWD/../build/nghttp2/$ANDROID_ARCH


make -j$CORES
make install
make clean
mkdir -p ../build/curl/$ANDROID_ARCH
cp -R $PWD/build/$ANDROID_ARCH ../build/curl/

# arm
export TARGET_HOST=armv7a-linux-androideabi
export ANDROID_ARCH=armeabi-v7a
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
export SSL_DIR=$PWD/../openssl/build/$ANDROID_ARCH
export LDFLAGS="-L$PWD/../build/nghttp2/$ANDROID_ARCH/lib"

./configure --host=$TARGET_HOST \
            --target=$TARGET_HOST \
            --prefix=$PWD/build/$ANDROID_ARCH \
            --with-openssl=$SSL_DIR $ARGUMENTS \
            --disable-shared --enable-static \
            --with-nghttp2=$PWD/../build/nghttp2/$ANDROID_ARCH

make -j$CORES
make install
make clean
mkdir -p ../build/curl/$ANDROID_ARCH
cp -R $PWD/build/$ANDROID_ARCH ../build/curl/

# x86
export TARGET_HOST=i686-linux-android
export ANDROID_ARCH=x86
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
export SSL_DIR=$PWD/../openssl/build/$ANDROID_ARCH
export LDFLAGS="-L$PWD/../build/nghttp2/$ANDROID_ARCH/lib"

./configure --host=$TARGET_HOST \
            --target=$TARGET_HOST \
            --prefix=$PWD/build/$ANDROID_ARCH \
            --with-openssl=$SSL_DIR $ARGUMENTS \
            --disable-shared --enable-static \
            --with-nghttp2=$PWD/../build/nghttp2/$ANDROID_ARCH

make -j$CORES
make install
make clean
mkdir -p ../build/curl/$ANDROID_ARCH
cp -R $PWD/build/$ANDROID_ARCH ../build/curl/

# x64
export TARGET_HOST=x86_64-linux-android
export ANDROID_ARCH=x86_64
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
export SSL_DIR=$PWD/../openssl/build/$ANDROID_ARCH
export LDFLAGS="-L$PWD/../build/nghttp2/$ANDROID_ARCH/lib"

./configure --host=$TARGET_HOST \
            --target=$TARGET_HOST \
            --prefix=$PWD/build/$ANDROID_ARCH \
            --with-openssl=$SSL_DIR $ARGUMENTS \
            --disable-shared --enable-static \
            --with-nghttp2=$PWD/../build/nghttp2/$ANDROID_ARCH

make -j$CORES
make install
make clean
mkdir -p ../build/curl/$ANDROID_ARCH
cp -R $PWD/build/$ANDROID_ARCH ../build/curl/

cd ..
