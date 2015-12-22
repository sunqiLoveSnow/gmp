#!/bin/bash

# TODO: cross-compile testsuite & run on a target device
# Building the tests without running them is easy; just do "make check TESTS=check"

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

export NDK="/tank/android/android-ndk-r10e"
if [ ! -d ${NDK} ]
then
  echo "Please download and install the NDK, then update the path in this script."
  echo "  http://developer.android.com/sdk/ndk/index.html"
  exit 1
fi

# Extract an Android toolchain, if needed
export TARGET32="android-19"
export TARGET64="android-21"
export TOOLCHAIN32="/tmp/${TARGET32}-arm32"
export TOOLCHAIN64="/tmp/${TARGET64}-arm64"
if [ ! -d ${TOOLCHAIN32} ]
then
  echo "======= EXTRACTING TOOLCHAIN FOR ARM32 ======="
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=arm-linux-androideabi-4.9 --platform=${TARGET32} --install-dir=${TOOLCHAIN32} --system=linux-x86_64
fi
if [ ! -d ${TOOLCHAIN64} ]
then
  echo "======= EXTRACTING TOOLCHAIN FOR ARM64 ======="
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=aarch64-linux-android-4.9 --platform=${TARGET64} --install-dir=${TOOLCHAIN64} --system=linux-x86_64
fi

export PATH="${TOOLCHAIN32}/bin:${TOOLCHAIN64}:${PATH}"
export LDFLAGS='-Wl,--fix-cortex-a8 -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now'
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

# The following line enables C++ support.  For GMP <= 5.1.2 you *must* apply gmp_decimal_point.patch prior to running this script.
export CPLUSPLUS_FLAGS='--enable-cxx'

################################################################################################################

BASE_CFLAGS='-O2 -g -pedantic -fomit-frame-pointer -Wa,--noexecstack -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64'

# armeabi-v7a with neon (unsupported target: will cause crashes on many phones, but works well on the Nexus One)
export CFLAGS="${BASE_CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=neon -ftree-vectorize -ftree-vectorizer-verbose=2"
./configure --prefix=/usr --disable-static ${CPLUSPLUS_FLAGS} --build=x86_64-pc-linux-gnu --host=arm-linux-androideabi MPN_PATH="arm/v6t2 arm/v6 arm/v5 arm generic"
make -j8 V=1 2>&1 | tee armeabi-v7a-neon.log
#make -j8 check TESTS=''
#TESTBASE='tests-armeabi-v7a-neon'
#find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
#tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
#rm -f ${TESTBASE}.txt
#xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/armeabi-v7a-neon
if [ -z "${CPLUSPLUS_FLAGS}" ]
then
  cd armeabi-v7a-neon && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
else
  cd armeabi-v7a-neon && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
fi
#mv ${TESTBASE}.tar.xz armeabi-v7a-neon
make distclean

# armeabi-v7a
export CFLAGS="${BASE_CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=vfp"
./configure --prefix=/usr --disable-static ${CPLUSPLUS_FLAGS} --build=x86_64-pc-linux-gnu --host=arm-linux-androideabi MPN_PATH="arm/v6t2 arm/v6 arm/v5 arm generic"
make -j8 V=1 2>&1 | tee armeabi-v7a.log
#make -j8 check TESTS=''
#TESTBASE='tests-armeabi-v7a'
#find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
#tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
#rm -f ${TESTBASE}.txt
#xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/armeabi-v7a
if [ -z "${CPLUSPLUS_FLAGS}" ]
then
  cd armeabi-v7a && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
else
  cd armeabi-v7a && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
fi
#mv ${TESTBASE}.tar.xz armeabi-v7a
make distclean

# armeabi
export CFLAGS="${BASE_CFLAGS} -march=armv5te -mtune=xscale -msoft-float -mthumb"
./configure --prefix=/usr --disable-static ${CPLUSPLUS_FLAGS} --build=x86_64-pc-linux-gnu --host=arm-linux-androideabi MPN_PATH="arm/v5 arm generic"
make -j8 V=1 2>&1 | tee armeabi.log
#make -j8 check TESTS=''
#TESTBASE='tests-armeabi'
#find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
#tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
#rm -f ${TESTBASE}.txt
#xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/armeabi
if [ -z "${CPLUSPLUS_FLAGS}" ]
then
  cd armeabi && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
else
  cd armeabi && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
fi
#mv ${TESTBASE}.tar.xz armeabi
make distclean

exit 0
