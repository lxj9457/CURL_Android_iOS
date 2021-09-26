# 请在 Intel CPU 下编译，M1暂不支持
# 请在当前目录下执行本脚本

CURL_VERSION="curl-7.78.0"
OPENSSL_TAG="1.1.1l"
NGHTTP2_TAG="1.44.0"
OPENSSL_VERSION="openssl-${OPENSSL_TAG}"
NGHTTP2_VERSION="nghttp2-${NGHTTP2_TAG}"

IOS_MIN_SDK_VERSION="9.0"
IOS_TARGET_VERSION="14.0"

export NDK=$HOME/Library/Android/sdk/ndk/21.3.6528147
export HOST_TAG=darwin-x86_64
export MIN_SDK_VERSION=21

WORKSPACE=`pwd`

rm -rf $WORKSPACE/output
rm -rf $WORKSPACE/${CURL_VERSION}
rm -rf $WORKSPACE/Android_build/openssl
rm -rf $WORKSPACE/Android_build/curl
rm -rf $WORKSPACE/${CURL_VERSION}
rm -rf $WORKSPACE/${OPENSSL_VERSION}
rm -rf $WORKSPACE/${CURL_VERSION}
mkdir $WORKSPACE/output
mkdir $WORKSPACE/output/iOS
mkdir $WORKSPACE/output/Android

# 下载
if [ ! -e ${NGHTTP2_VERSION}.tar.gz ]; then
	echo "Downloading ${NGHTTP2_VERSION}.tar.gz"
	curl -LOs https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_TAG}/${NGHTTP2_VERSION}.tar.gz
else
	echo "Using ${NGHTTP2_VERSION}.tar.gz"
fi

echo "Unpacking nghttp2"
tar xfz "${NGHTTP2_VERSION}.tar.gz"

if [ ! -e ${OPENSSL_VERSION}.tar.gz ]; then
	echo "Downloading ${OPENSSL_VERSION}.tar.gz"
	curl -LOs https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
else
	echo "Using ${OPENSSL_VERSION}.tar.gz"
fi

echo "Unpacking openssl"
tar xfz "${OPENSSL_VERSION}.tar.gz"

if [ ! -e ${CURL_VERSION}.tar.gz ]; then
	echo "Downloading ${CURL_VERSION}.tar.gz"
	curl -LOs https://curl.haxx.se/download/${CURL_VERSION}.tar.gz
else
	echo "Using ${CURL_VERSION}.tar.gz"
fi

echo "Unpacking curl"
tar xfz "${CURL_VERSION}.tar.gz"

# 编译 iOS OPENSSL
cp -r $WORKSPACE/${NGHTTP2_VERSION} $WORKSPACE/iOS_build/nghttp2
cd $WORKSPACE/iOS_build/nghttp2
chmod +x ios-nghttp2-build.sh
sh ios-nghttp2-build.sh ${NGHTTP2_TAG} ${IOS_MIN_SDK_VERSION}

# 编译 iOS OPENSSL
cp -r $WORKSPACE/${OPENSSL_VERSION} $WORKSPACE/iOS_build/openssl
cd $WORKSPACE/iOS_build/openssl
chmod +x ios-openssl-build.sh
sh ios-openssl-build.sh ${OPENSSL_TAG} ${IOS_MIN_SDK_VERSION}

# 编译 iOS CURL
cp -r $WORKSPACE/${CURL_VERSION} $WORKSPACE/iOS_build/curl
cd $WORKSPACE/iOS_build/curl
chmod +x ios-curl-build.sh
sh ios-curl-build.sh ${CURL_VERSION} ${IOS_MIN_SDK_VERSION}

mkdir $WORKSPACE/output/iOS/openssl.framework
mkdir $WORKSPACE/output/iOS/curl.framework
mkdir $WORKSPACE/output/iOS/nghttp2.framework
mkdir $WORKSPACE/output/iOS/openssl.framework/Headers
mkdir $WORKSPACE/output/iOS/openssl.framework/Modules
mkdir $WORKSPACE/output/iOS/nghttp2.framework/Headers
mkdir $WORKSPACE/output/iOS/nghttp2.framework/Modules
mkdir $WORKSPACE/output/iOS/curl.framework/Headers
mkdir $WORKSPACE/output/iOS/curl.framework/Modules

cp -r $WORKSPACE/iOS_build/openssl/iOS-fat/include/openssl/* $WORKSPACE/output/iOS/openssl.framework/Headers
cp $WORKSPACE/iOS_build/openssl/iOS-fat/lib/libssl.a $WORKSPACE/output/iOS/openssl.framework/openssl.a
cp $WORKSPACE/iOS_build/openssl/iOS-fat/lib/libcrypto.a $WORKSPACE/output/iOS/openssl.framework/crypto.a
cp -r $WORKSPACE/iOS_build/curl/include/curl/* $WORKSPACE/output/iOS/curl.framework/Headers
cp $WORKSPACE/iOS_build/curl/lib/libcurl_iOS-fat.a $WORKSPACE/output/iOS/curl.framework/curl
cp $WORKSPACE/iOS_build/nghttp2/lib/libnghttp2_iOS-fat.a $WORKSPACE/output/iOS/nghttp2.framework/nghttp2
cp $WORKSPACE/iOS_build/nghttp2/include/nghttp2/* $WORKSPACE/output/iOS/nghttp2.framework/Headers

cd $WORKSPACE/output/iOS/openssl.framework
ARCHS=( armv7 armv7s x86_64 arm64 arm64e )
for element in ${ARCHS[@]}
do
mkdir $element
lipo crypto.a -thin $element -output crypto_$element.a
lipo openssl.a -thin $element -output openssl_$element.a
mv crypto_$element.a $element
mv openssl_$element.a $element
cd $element
ar -x crypto_$element.a
ar -x openssl_$element.a
libtool -static -o new_openssl_$element.a *.o
cd ../
mv $element/new_openssl_$element.a new_openssl_$element.a
done
rm openssl.a
rm crypto.a
echo "lipo -create new_openssl_armv7.a new_openssl_armv7s.a new_openssl_x86_64.a new_openssl_arm64.a new_openssl_arm64e.a -output new_openssl.a"
lipo -create new_openssl_armv7.a new_openssl_armv7s.a new_openssl_x86_64.a new_openssl_arm64.a new_openssl_arm64e.a -output new_openssl.a
for element in ${ARCHS[@]}
do
	rm -rf $element 
	rm openssl_$element.a
	rm crypto_$element.a
	rm new_openssl_$element.a
done
mv new_openssl.a openssl

cd $WORKSPACE

编译 Android OPENSSL
cp -r $WORKSPACE/${OPENSSL_VERSION} $WORKSPACE/Android_build/openssl
cd $WORKSPACE/Android_build
chmod +x android-openssl-build.sh
sh android-openssl-build.sh

# 编译 Android NGHTTP2
cp -r $WORKSPACE/${NGHTTP2_VERSION} $WORKSPACE/Android_build/nghttp2
cd $WORKSPACE/Android_build
chmod +x android-nghttp2-build.sh
sh android-nghttp2-build.sh

# 编译 Android CURL
cp -r $WORKSPACE/${CURL_VERSION} $WORKSPACE/Android_build/curl
cd $WORKSPACE/Android_build
chmod +x android-curl-build.sh
sh android-curl-build.sh

mv $WORKSPACE/Android_build/build/* $WORKSPACE/output/Android