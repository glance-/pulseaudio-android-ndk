#!/bin/bash
set -e
export ANDROID_NDK_ROOT=$PWD/../android-ndk-r9d

# arm or x86
export ARCH=${1-arm}

if [ "$ARCH" = "arm" ] ; then
	BUILDCHAIN=arm-linux-androideabi
else if [ "$ARCH" = "x86" ] ; then
	BUILDCHAIN=i686-linux-android
fi fi
if [ ! -e ndk-$ARCH ] ; then
	$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh --arch=$ARCH --install-dir=ndk-$ARCH --platform=android-14
fi
export BUILDROOT=$PWD
export PATH=${BUILDROOT}/ndk-$ARCH/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-$ARCH/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export CC=${BUILDCHAIN}-gcc
export CXX=${BUILDCHAIN}-g++

# Fetch external repos
if [ ! -e pulseaudio ] || [ ! -e json-c ] || [ ! -e libtool ] ; then
	git submodule init
	git submodule update
fi

if [ ! -e ${PREFIX}/lib/libltdl.a ] ; then
	pushd libtool
	env HELP2MAN=/bin/true MAKEINFO=/bin/true ./bootstrap
	popd
	mkdir -p libtool-build
	pushd libtool-build
	../libtool/configure --host=${BUILDCHAIN} --prefix=${PREFIX} HELP2MAN=/bin/true MAKEINFO=/bin/true
	make
	make install ||:
	popd
fi

# Now, use updated libtool
export LIBTOOLIZE=${PREFIX}/bin/libtoolize

if [ ! -e $PKG_CONFIG_PATH/json-c.pc ] ; then
	pushd json-c
	autoreconf -i
	aclocal --system-acdir=${PREFIX}/share/aclocal
	popd
	mkdir -p json-c-build
	pushd json-c-build
	../json-c/configure --host=${BUILDCHAIN} --prefix=${PREFIX}
	make
	make install
	popd
fi

if [ ! -e libsndfile-1.0.25.tar.gz ] ; then
	wget http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.25.tar.gz
fi
if [ ! -e libsndfile-1.0.25 ] ; then
	tar -zxf libsndfile-1.0.25.tar.gz
fi
if [ ! -e $PKG_CONFIG_PATH/sndfile.pc ] ; then
	pushd libsndfile-1.0.25
	cp ../json-c/config.sub Cfg/
	popd
	mkdir -p libsndfile-build
	pushd libsndfile-build
	../libsndfile-1.0.25/configure --host=${BUILDCHAIN} --prefix=${PREFIX} --disable-external-libs --disable-alsa --disable-sqlite
	make ||:
	make install ||:
	cp sndfile.pc ${PREFIX}/lib/pkgconfig/
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

mkdir -p pulseaudio-build
pushd pulseaudio-build
../pulseaudio/configure --host=${BUILDCHAIN} --prefix=${PREFIX} --enable-static --disable-rpath --disable-nls --disable-x11 --disable-oss-wrapper --disable-alsa --disable-esound --disable-waveout --disable-glib2 --disable-gtk3 --disable-gconf --disable-avahi --disable-jack --disable-asyncns --disable-tcpwrap --disable-lirc --disable-dbus --disable-bluez4 --disable-bluez5 --disable-udev --disable-openssl --disable-xen --disable-systemd --disable-manpages --disable-samplerate --without-speex --with-database=simple --disable-orc --without-caps
# --enable-static-bins
make
make install
