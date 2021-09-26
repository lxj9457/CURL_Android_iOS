#!/bin/bash

set -e

# Formatting
default="\033[39m"
wihte="\033[97m"
green="\033[32m"
red="\033[91m"
yellow="\033[33m"

bold="\033[0m${green}\033[1m"
subbold="\033[0m${green}"
archbold="\033[0m${yellow}\033[1m"
normal="${white}\033[0m"
dim="\033[0m${white}\033[2m"
alert="\033[0m${red}\033[1m"
alertdim="\033[0m${red}\033[2m"

# Set trap to help debug any build errors
trap 'echo -e "${alert}** ERROR with Build - Check /tmp/curl*.log${alertdim}"; tail -3 /tmp/curl*.log' INT TERM EXIT

# Set defaults
CURL_VERSION=$1
IOS_MIN_SDK_VERSION=$2
IOS_SDK_VERSION=""

if [ ! -n $CURL_VERSION ]; then
	$CURL_VERSION="curl-7.78.0"
fi

if [ ! -n $IOS_MIN_SDK_VERSION ]; then
	$IOS_MIN_SDK_VERSION="9.0"
fi

WITH_NGHTTP2="0"
CORES=$(sysctl -n hw.ncpu)
OPENSSL="${PWD}/../openssl"
DEVELOPER=`xcode-select -print-path`


# HTTP2 support
if [ $WITH_NGHTTP2 == "1" ]; then
	# nghttp2 will be in ../nghttp2/{Platform}/{arch}
	NGHTTP2="${PWD}/../nghttp2"
fi

if [ $WITH_NGHTTP2 == "1" ]; then
	echo "Building with HTTP2 Support (nghttp2)"
else
	echo "Building without HTTP2 Support (nghttp2)"
	NGHTTP2CFG=""
	NGHTTP2LIB=""
fi

# Check to see if pkg-config is already installed
PATH=$PATH:/tmp/pkg_config/bin
if ! (type "pkg-config" > /dev/null 2>&1 ) ; then
	echo -e "${alertdim}** WARNING: pkg-config not installed... attempting to install.${dim}"

	# Check to see if Brew is installed
	if (type "brew" > /dev/null 2>&1 ) ; then
		echo "  brew installed - using to install pkg-config"
		brew install pkg-config
	else
		# Build pkg-config from Source
		curl -LOs https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
		echo "  Building pkg-config"
		tar xfz pkg-config-0.29.2.tar.gz
		pushd pkg-config-0.29.2 > /dev/null
		./configure --prefix=/tmp/pkg_config --with-internal-glib >> "/tmp/${NGHTTP2_VERSION}.log" 2>&1
		make >> "/tmp/${NGHTTP2_VERSION}.log" 2>&1
		make install >> "/tmp/${NGHTTP2_VERSION}.log" 2>&1
		popd > /dev/null
	fi

	# Check to see if installation worked
	if (type "pkg-config" > /dev/null 2>&1 ) ; then
		echo "  SUCCESS: pkg-config now installed"
	else
		echo -e "${alert}** FATAL ERROR: pkg-config failed to install - exiting.${normal}"
		exit 1
	fi
fi

buildIOS()
{
	ARCH=$1
	BITCODE=$2

	pushd . > /dev/null
	cd "${CURL_VERSION}"

	PLATFORM="iPhoneOS"
	PLATFORMDIR="iOS"

	if [[ "${BITCODE}" == "nobitcode" ]]; then
		CC_BITCODE_FLAG=""
	else
		CC_BITCODE_FLAG="-fembed-bitcode"
	fi

	if [ $WITH_NGHTTP2 == "1" ]; then
		NGHTTP2CFG="--with-nghttp2=${NGHTTP2}/${PLATFORMDIR}/${ARCH}"
		NGHTTP2LIB="-L${NGHTTP2}/${PLATFORMDIR}/${ARCH}/lib"
	fi

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export CC="${DEVELOPER}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${CC_BITCODE_FLAG}"

	echo -e "${subbold}Building ${CURL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${archbold}${ARCH}${dim} ${BITCODE} (iOS ${IOS_MIN_SDK_VERSION})"

	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -L${OPENSSL}/${PLATFORMDIR}/lib ${NGHTTP2LIB}"
	if [[ "${ARCH}" == *"arm64"* || "${ARCH}" == "arm64e" ]]; then
		./configure -prefix="/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}" --disable-shared --enable-static -with-random=/dev/urandom --with-ssl=${OPENSSL}/${PLATFORMDIR} ${NGHTTP2CFG} --host="arm-apple-darwin" &> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	else
		echo "./configure -prefix=\"/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}\" --disable-shared --enable-static -with-random=/dev/urandom --with-ssl=${OPENSSL}/${PLATFORMDIR} ${NGHTTP2CFG} --host=\"${ARCH}-apple-darwin\" &> \"/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log\""
		./configure -prefix="/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}" --disable-shared --enable-static -with-random=/dev/urandom --with-ssl=${OPENSSL}/${PLATFORMDIR} ${NGHTTP2CFG} --host="${ARCH}-apple-darwin" &> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	fi
	echo "make -j${CORES} >> \"/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log\" 2>&1"
	make -j${CORES} >> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make install >> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make clean >> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	popd > /dev/null
}

buildIOSsim()
{
	ARCH=$1
	BITCODE=$2

	pushd . > /dev/null
	cd "${CURL_VERSION}"

	PLATFORM="iPhoneSimulator"
	PLATFORMDIR="iOS-simulator"

	if [[ "${BITCODE}" == "nobitcode" ]]; then
		CC_BITCODE_FLAG=""
	else
		CC_BITCODE_FLAG="-fembed-bitcode"
	fi

	if [ $WITH_NGHTTP2 == "1" ]; then
		NGHTTP2CFG="--with-nghttp2=${NGHTTP2}/${PLATFORMDIR}/${ARCH}"
		NGHTTP2LIB="-L${NGHTTP2}/${PLATFORMDIR}/${ARCH}/lib"
	fi

	TARGET="darwin-i386-cc"
	RUNTARGET=""
	MIPHONEOS="${IOS_MIN_SDK_VERSION}"
	if [[ $ARCH != "i386" ]]; then
		TARGET="darwin64-${ARCH}-cc"
		RUNTARGET="-target ${ARCH}-apple-ios${IOS_MIN_SDK_VERSION}-simulator"
	fi

	# set up exports for build 
	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export CC="${DEVELOPER}/usr/bin/gcc"
	export CXX="${DEVELOPER}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${MIPHONEOS} ${CC_BITCODE_FLAG} ${RUNTARGET} "
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -L${OPENSSL}/${PLATFORMDIR}/lib ${NGHTTP2LIB} "
	export CPPFLAGS=" -I.. -isysroot ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk "

	echo -e "${subbold}Building ${CURL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${archbold}${ARCH}${dim} ${BITCODE} (iOS ${IOS_MIN_SDK_VERSION})"

	if [[ "${ARCH}" == *"arm64"* || "${ARCH}" == "arm64e" ]]; then
		./configure -prefix="/tmp/${CURL_VERSION}-iOS-simulator-${ARCH}-${BITCODE}" --disable-shared --enable-static -with-random=/dev/urandom --with-ssl=${OPENSSL}/${PLATFORMDIR} ${NGHTTP2CFG} --host="arm-apple-darwin" &> "/tmp/${CURL_VERSION}-iOS-simulator-${ARCH}-${BITCODE}.log"
	else
		./configure -prefix="/tmp/${CURL_VERSION}-iOS-simulator-${ARCH}-${BITCODE}" --disable-shared --enable-static -with-random=/dev/urandom --with-ssl=${OPENSSL}/${PLATFORMDIR} ${NGHTTP2CFG} --host="${ARCH}-apple-darwin" &> "/tmp/${CURL_VERSION}-iOS-simulator-${ARCH}-${BITCODE}.log"
	fi

	make -j${CORES} >> "/tmp/${CURL_VERSION}-iOS-simulator-${ARCH}-${BITCODE}.log" 2>&1
	make install >> "/tmp/${CURL_VERSION}-iOS-simulator-${ARCH}-${BITCODE}.log" 2>&1
	make clean >> "/tmp/${CURL_VERSION}-iOS-simulator-${ARCH}-${BITCODE}.log" 2>&1
	popd > /dev/null
}


echo -e "${bold}Cleaning up${dim}"
rm -rf include/curl/* lib/*

mkdir -p lib
mkdir -p include/curl/

rm -fr "/tmp/curl"
rm -rf "/tmp/${CURL_VERSION}-*"
rm -rf "/tmp/${CURL_VERSION}-*.log"

echo -e "${bold}Building iOS libraries (bitcode)${dim}"
buildIOS "armv7" "bitcode"
buildIOS "armv7s" "bitcode"
buildIOS "arm64" "bitcode"
buildIOS "arm64e" "bitcode"

cp /tmp/${CURL_VERSION}-iOS-arm64e-bitcode/include/curl/* include/curl/

lipo \
	"/tmp/${CURL_VERSION}-iOS-armv7-bitcode/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-armv7s-bitcode/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-arm64-bitcode/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-arm64e-bitcode/lib/libcurl.a" \
	-create -output lib/libcurl_iOS.a

buildIOSsim "x86_64" "bitcode"
buildIOSsim "arm64" "bitcode"

lipo \
	"/tmp/${CURL_VERSION}-iOS-simulator-x86_64-bitcode/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-simulator-arm64-bitcode/lib/libcurl.a" \
	-create -output lib/libcurl_iOS-simulator.a

lipo \
	"/tmp/${CURL_VERSION}-iOS-armv7-bitcode/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-armv7s-bitcode/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-arm64-bitcode/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-arm64e-bitcode/lib/libcurl.a" \
	"/tmp/${CURL_VERSION}-iOS-simulator-x86_64-bitcode/lib/libcurl.a" \
	-create -output lib/libcurl_iOS-fat.a

if [[ "${NOBITCODE}" == "yes" ]]; then
	echo -e "${bold}Building iOS libraries (nobitcode)${dim}"
	buildIOS "armv7" "nobitcode"
	buildIOS "armv7s" "nobitcode"
	buildIOS "arm64" "nobitcode"
	buildIOS "arm64e" "nobitcode"
	buildIOSsim "x86_64" "nobitcode"

	lipo \
		"/tmp/${CURL_VERSION}-iOS-armv7-nobitcode/lib/libcurl.a" \
		"/tmp/${CURL_VERSION}-iOS-armv7s-nobitcode/lib/libcurl.a" \
		"/tmp/${CURL_VERSION}-iOS-arm64-nobitcode/lib/libcurl.a" \
		"/tmp/${CURL_VERSION}-iOS-arm64e-nobitcode/lib/libcurl.a" \
		"/tmp/${CURL_VERSION}-iOS-simulator-x86_64-nobitcode/lib/libcurl.a" \
		-create -output lib/libcurl_iOS_nobitcode.a

fi

echo -e "${bold}Cleaning up${dim}"
rm -rf /tmp/${CURL_VERSION}-*
rm -rf ${CURL_VERSION}

echo "Checking libraries"
xcrun -sdk iphoneos lipo -info lib/*.a

#reset trap
trap - INT TERM EXIT

echo -e "${normal}Done"
