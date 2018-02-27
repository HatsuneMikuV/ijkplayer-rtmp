#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script is based on projects below

#--------------------
echo "===================="
echo "[*] check host"
echo "===================="
set -e


FF_XCRUN_DEVELOPER=`xcode-select -print-path`
if [ ! -d "$FF_XCRUN_DEVELOPER" ]; then
  echo "xcode path is not set correctly $FF_XCRUN_DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $FF_XCRUN_DEVELOPER in
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac


#--------------------
# include


#--------------------
# common defines
FF_ARCH=$1
if [ -z "$FF_ARCH" ]; then
    echo "You must specific an architecture 'armv7, armv7s, arm64, i386, x86_64, ...'.\n"
    exit 1
fi


FF_BUILD_ROOT=`pwd`
FF_TAGET_OS="darwin"


# rtmp build params
export COMMON_FF_CFG_FLAGS=

RTMP_CFG_FLAGS=
RTMP_EXTRA_CFLAGS=
RTMP_CFG_CPU=

# i386, x86_64
RTMP_CFG_FLAGS_SIMULATOR=

# armv7, armv7s, arm64
RTMP_CFG_FLAGS_ARM=
RTMP_CFG_FLAGS_ARM="--host=arm-apple-darwin"

echo "build_root: $FF_BUILD_ROOT"

#--------------------
echo "===================="
echo "[*] config arch $FF_ARCH"
echo "===================="

FF_BUILD_NAME="unknown"
FF_XCRUN_PLATFORM="iPhoneOS"
FF_XCRUN_OSVERSION=
FF_GASPP_EXPORT=

if [ "$FF_ARCH" = "i386" ]; then
    FF_BUILD_NAME="rtmp-i386"
    FF_BUILD_NAME_OPENSSL=openssl-i386
    FF_XCRUN_PLATFORM="iPhoneSimulator"
    FF_XCRUN_OSVERSION="-mios-simulator-version-min=6.0"
elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_BUILD_NAME="rtmp-x86_64"
    FF_BUILD_NAME_OPENSSL=openssl-x86_64
    FF_XCRUN_PLATFORM="iPhoneSimulator"
    FF_XCRUN_OSVERSION="-mios-simulator-version-min=7.0"
elif [ "$FF_ARCH" = "armv7" ]; then
    FF_BUILD_NAME="rtmp-armv7"
    FF_BUILD_NAME_OPENSSL=openssl-armv7
    FF_XCRUN_OSVERSION="-miphoneos-version-min=6.0"
    RTMP_CFG_FLAGS="--disable-neon $RTMP_CFG_FLAGS_ARM $RTMP_CFG_FLAGS"
#    OPENSSL_CFG_CPU="--cpu=cortex-a8"
elif [ "$FF_ARCH" = "armv7s" ]; then
    FF_BUILD_NAME="rtmp-armv7s"
    FF_BUILD_NAME_OPENSSL=openssl-armv7s
    RTMP_CFG_CPU="--cpu=swift"
    FF_XCRUN_OSVERSION="-miphoneos-version-min=6.0"
    RTMP_CFG_FLAGS="--disable-neon $RTMP_CFG_FLAGS_ARM $RTMP_CFG_FLAGS"
elif [ "$FF_ARCH" = "arm64" ]; then
    FF_BUILD_NAME="rtmp-arm64"
    FF_BUILD_NAME_OPENSSL=openssl-arm64
    FF_XCRUN_OSVERSION="-miphoneos-version-min=7.0"
    RTMP_CFG_FLAGS="--disable-neon $RTMP_CFG_FLAGS_ARM $RTMP_CFG_FLAGS"
    FF_GASPP_EXPORT="GASPP_FIX_XCODE5=1"
else
    echo "unknown architecture $FF_ARCH";
    exit 1
fi

echo "build_name: $FF_BUILD_NAME"
echo "platform:   $FF_XCRUN_PLATFORM"
echo "osversion:  $FF_XCRUN_OSVERSION"

#--------------------
echo "===================="
echo "[*] make ios toolchain $FF_BUILD_NAME"
echo "===================="


FF_BUILD_SOURCE="$FF_BUILD_ROOT/$FF_BUILD_NAME"
FF_BUILD_PREFIX="$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output"

mkdir -p $FF_BUILD_PREFIX


FF_XCRUN_SDK=`echo $FF_XCRUN_PLATFORM | tr '[:upper:]' '[:lower:]'`
FF_XCRUN_SDK_PLATFORM_PATH=`xcrun -sdk $FF_XCRUN_SDK --show-sdk-platform-path`
FF_XCRUN_SDK_PATH=`xcrun -sdk $FF_XCRUN_SDK --show-sdk-path`
FF_XCRUN_CC="xcrun -sdk $FF_XCRUN_SDK clang"

export CROSS_TOP="$FF_XCRUN_SDK_PLATFORM_PATH/Developer"
export CROSS_SDK=`echo ${FF_XCRUN_SDK_PATH/#$CROSS_TOP\/SDKs\//}`
export BUILD_TOOL="$FF_XCRUN_DEVELOPER"
export CC="$FF_XCRUN_CC -arch $FF_ARCH $FF_XCRUN_OSVERSION"

echo "build_source: $FF_BUILD_SOURCE"
echo "build_prefix: $FF_BUILD_PREFIX"
echo "CROSS_TOP: $CROSS_TOP"
echo "CROSS_SDK: $CROSS_SDK"
echo "BUILD_TOOL: $BUILD_TOOL"
echo "CC: $CC"

#--------------------
echo "\n--------------------"
echo "[*] check OpenSSL"
echo "----------------------"
FFMPEG_DEP_OPENSSL=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/include
FFMPEG_DEP_OPENSSL_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/lib
#--------------------
# with openssl
if [ -f "${FFMPEG_DEP_OPENSSL_LIB}/libssl.a" ]; then
    RTMP_CFG_FLAGS="$FFMPEG_CFLAGS -I${FFMPEG_DEP_OPENSSL}"
fi

#--------------------
echo "\n--------------------"
echo "[*] configurate rtmp"
echo "--------------------"

RTMP_CFG_FLAGS="$RTMP_CFG_FLAGS --prefix=$FF_BUILD_PREFIX"

# xcode configuration
export DEBUG_INFORMATION_FORMAT=dwarf-with-dsym

cd $FF_BUILD_SOURCE
if [ -f "./Makefile" ]; then
    echo 'reuse configure'
elif [ -f "./configure" ]; then
    echo 'already run autogen.sh'
    echo "config: $RTMP_CFG_FLAGS"
    ./Configure \
        $RTMP_CFG_FLAGS
    make clean
else
    echo 'should run autogen.sh first'
    ./autogen.sh

    echo "config: $RTMP_CFG_FLAGS"
    ./Configure \
        $RTMP_CFG_FLAGS
    make clean
fi

#--------------------
echo "\n--------------------"
echo "[*] compile rtmp"
echo "--------------------"
set +e
make
make install
