#!/bin/bash
set -e
export ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT-$PWD/../android-ndk-r13b}

# arm or x86
export ARCH=${1-arm}

if [ "$ARCH" = "arm" ] ; then
	BUILDCHAIN=arm-linux-androideabi
elif [ "$ARCH" = "x86" ] ; then
	BUILDCHAIN=i686-linux-android
elif [ "$ARCH" = "x86_64" ] ; then
	BUILDCHAIN=x86_64-linux-android
fi

LIBTOOL_VERSION=2.4.6
LIBSNDFILE_VERSION=1.0.27

if [ ! -e "ndk-$ARCH" ] ; then
	"$ANDROID_NDK_ROOT"/build/tools/make_standalone_toolchain.py --arch="$ARCH" --install-dir="ndk-$ARCH" --api=24
fi
export BUILDROOT=$PWD
export PATH=${BUILDROOT}/ndk-$ARCH/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-$ARCH/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export CC=${BUILDCHAIN}-gcc
export CXX=${BUILDCHAIN}-g++
export CPPFLAGS="-Dposix_madvise=madvise -DPOSIX_MADV_WILLNEED=MADV_WILLNEED"
export ACLOCAL_PATH=${PREFIX}/share/aclocal

# Fetch external repos
if [ ! -e pulseaudio ] ; then
	git submodule init
	git submodule update
fi

if [ ! -e libtool-$LIBTOOL_VERSION.tar.gz ] ; then
	wget http://ftpmirror.gnu.org/libtool/libtool-$LIBTOOL_VERSION.tar.gz
fi
if [ ! -e libtool-$LIBTOOL_VERSION ] ; then
	tar -zxf libtool-$LIBTOOL_VERSION.tar.gz
fi
if [ ! -e "${PREFIX}/lib/libltdl.a" ] ; then
	mkdir -p "libtool-build-$ARCH"
	pushd "libtool-build-$ARCH"
	../libtool-$LIBTOOL_VERSION/configure --host=${BUILDCHAIN} --prefix="${PREFIX}" HELP2MAN=/bin/true MAKEINFO=/bin/true
	make
	make install
	popd
fi

# Now, use updated libtool
export LIBTOOLIZE=${PREFIX}/bin/libtoolize

if [ ! -e libsndfile-$LIBSNDFILE_VERSION.tar.gz ] ; then
	wget http://www.mega-nerd.com/libsndfile/files/libsndfile-$LIBSNDFILE_VERSION.tar.gz
fi
if [ ! -e libsndfile-$LIBSNDFILE_VERSION ] ; then
	tar -zxf libsndfile-$LIBSNDFILE_VERSION.tar.gz
fi
if [ ! -e "$PKG_CONFIG_PATH/sndfile.pc" ] ; then
	mkdir -p "libsndfile-build-$ARCH"
	pushd "libsndfile-build-$ARCH"
	../libsndfile-$LIBSNDFILE_VERSION/configure --host=${BUILDCHAIN} --prefix="${PREFIX}" --disable-external-libs --disable-alsa --disable-sqlite
	# Hack out examples, which doesn't build
	perl -pi -e 's/ examples / /g' Makefile
	make
	make install
	popd
fi

pushd pulseaudio
# disable patching for now..
#if ! git grep -q opensl ; then
#	git am ../pulseaudio-patches/*
#fi
env NOCONFIGURE=1 bash -x ./bootstrap.sh
#./autogen.sh
popd

mkdir -p "pulseaudio-build-$ARCH"
pushd "pulseaudio-build-$ARCH"
../pulseaudio/configure --host=${BUILDCHAIN} --prefix="${PREFIX}" --enable-static --disable-rpath --disable-nls --disable-x11 --disable-oss-wrapper --disable-alsa --disable-esound --disable-waveout --disable-glib2 --disable-gtk3 --disable-gconf --disable-avahi --disable-jack --disable-asyncns --disable-tcpwrap --disable-lirc --disable-dbus --disable-bluez4 --disable-bluez5 --disable-udev --disable-openssl --disable-xen --disable-systemd --disable-manpages --disable-samplerate --without-speex --with-database=simple --disable-orc --without-caps --without-fftw --disable-systemd-daemon --disable-systemd-login --disable-systemd-journal --disable-webrtc-aec --disable-tests
# --enable-static-bins
make
make install
