#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
    export CORES=$((`sysctl -n hw.logicalcpu`+1))
else
    export CORES=$((`nproc`+1))
fi

export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG

export ANDROID_NDK_HOME=$NDK
PATH=$TOOLCHAIN/bin:$PATH

mkdir -p build/nghttp2
cd nghttp2

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

echo "./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix=\"$PWD/build/$ANDROID_ARCH\" --host=\"${TARGET_HOST}\""
./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix="$PWD/build/$ANDROID_ARCH" --host="${TARGET_HOST}"

make -j$CORES
make install
make clean
mkdir -p ../build/nghttp2/$ANDROID_ARCH
cp -R $PWD/build/$ANDROID_ARCH ../build/nghttp2/

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
echo "./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix=\"$PWD/build/$ANDROID_ARCH\" --host=\"${TARGET_HOST}\""
./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix="$PWD/build/$ANDROID_ARCH" --host="${TARGET_HOST}"

make -j$CORES
make install
make clean
mkdir -p ../build/nghttp2/$ANDROID_ARCH
cp -R $PWD/build/$ANDROID_ARCH ../build/nghttp2/

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

echo "./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix=\"$PWD/build/$ANDROID_ARCH\" --host=\"${TARGET_HOST}\""
./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix="$PWD/build/$ANDROID_ARCH" --host="${TARGET_HOST}"
make -j$CORES
make install
make clean
mkdir -p ../build/nghttp2/$ANDROID_ARCH
cp -R $PWD/build/$ANDROID_ARCH ../build/nghttp2/

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

echo "./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix=\"$PWD/build/$ANDROID_ARCH\" --host=\"${TARGET_HOST}\""
./configure --disable-shared --disable-app --disable-threads --enable-lib-only  --prefix="$PWD/build/$ANDROID_ARCH" --host="${TARGET_HOST}"

make -j$CORES
make install
make clean
mkdir -p ../build/nghttp2/$ANDROID_ARCH
cp -R $PWD/build/$ANDROID_ARCH ../build/nghttp2/

cd ..
