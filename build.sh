set -e
export ANDROID_NDK_ROOT=$PWD/../android-ndk-r9c
if [ ! -e ndk-arm ] ; then
	$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh --install-dir=ndk-arm --platform=android-14
fi
export BUILDROOT=$PWD
export PATH=${BUILDROOT}/ndk-arm/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-arm/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

# Fetch external repos
git submodule update
git submodule foreach --recursive git checkout master

if [ ! -e ./ndk-arm/sysroot/usr/lib/libltdl.a ] ; then
	pushd libtool
	env HELP2MAN=/bin/true MAKEINFO=/bin/true ./bootstrap
	popd
	mkdir -p libtool-build
	pushd libtool-build
	../libtool/configure --host=arm-linux-androideabi --prefix=${PREFIX} HELP2MAN=/bin/true MAKEINFO=/bin/true
	make
	make install ||:
	popd
fi

# Now, use updated libtool
export LIBTOOLIZE=${PREFIX}/bin/libtoolize

if [ ! -e $PKG_CONFIG_PATH/json-c.pc ] ; then
	pushd json-c
	git am ../json-c-patches/*
	./autogen.sh
	popd
	mkdir -p json-c-build
	pushd json-c-build
	../json-c/configure --host=arm-linux-androideabi --prefix=${PREFIX}
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
	../libsndfile-1.0.25/configure --host=arm-linux-androideabi --prefix=${PREFIX} --disable-external-libs --disable-alsa --disable-sqlite
	make ||:
	make install ||:
	cp sndfile.pc ${PREFIX}/lib/pkgconfig/
	popd
fi

pushd pulseaudio
# disable patching for now..
#if ! git grep -q __ANDROID__ ; then
#	git am ../pulseaudio-patches/*
#fi
env NOCONFIGURE=1 bash -x ./bootstrap.sh
#./autogen.sh
popd

mkdir -p pulseaudio-build
pushd pulseaudio-build
../pulseaudio/configure --host=arm-linux-androideabi --prefix=${PREFIX} --enable-static --disable-rpath --disable-nls --disable-x11 --disable-oss-wrapper --disable-alsa --disable-esound --disable-waveout --disable-glib2 --disable-gtk3 --disable-gconf --disable-avahi --disable-jack --disable-asyncns --disable-tcpwrap --disable-lirc --disable-dbus --disable-bluez --disable-udev --disable-openssl --disable-xen --disable-systemd --disable-manpages --disable-samplerate --without-speex --with-database=simple --disable-orc --without-caps
# --enable-static-bins
make
make install
