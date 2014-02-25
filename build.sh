set -e
if [ ! -e ndk-arm ] ; then
	 ../android-ndk-r9c/build/tools/make-standalone-toolchain.sh --install-dir=ndk-arm --platform=android-14
fi
export BUILDROOT=$PWD
export PATH=${BUILDROOT}/ndk-arm/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-arm/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

git submodule update
git submodule foreach --recursive git checkout master

if [ ! -e $PKG_CONFIG_PATH/json.pc ] ; then
cd json-c
./autogen.sh
./configure --host=arm-linux-androideabi --prefix=${PREFIX}
make
make install
cd ..
fi

if [ ! -e libsndfile-1.0.25.tar.gz ] ; then
	wget http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.25.tar.gz
fi
if [ ! -e libsndfile-1.0.25 ] ; then
	tar -zxf libsndfile-1.0.25.tar.gz
fi
if [ ! -e $PKG_CONFIG_PATH/sndfile.pc ] ; then
cd libsndfile-1.0.25
cp ../json-c/config.sub Cfg/
./configure --host=arm-linux-androideabi --prefix=${PREFIX} --disable-external-libs --disable-alsa --disable-sqlite
make ||:
make install ||:
cp sndfile.pc ${PREFIX}/lib/pkgconfig/
cd ..
fi

if [ ! -e libtool_2.4.2.orig.tar.gz ] ; then
wget http://ftp.de.debian.org/debian/pool/main/libt/libtool/libtool_2.4.2.orig.tar.gz
fi
if [ ! -e libtool-2.4.2 ] ; then
tar -zxf libtool_2.4.2.orig.tar.gz
fi
if [ ! -e ./ndk-arm/sysroot/usr/lib/libltdl.a ] ; then
cd libtool-2.4.2
./configure --host=arm-linux-androideabi --prefix=${PREFIX}
make
make install
cd ..
fi

cd pulseaudio
if ! git grep -q __ANDROID__ ; then
	git am ../patches/*
fi
env NOCONFIGURE=1 bash -x ./bootstrap.sh
#./autogen.sh
./configure --host=arm-linux-androideabi --prefix=${PREFIX} --enable-static --disable-rpath --disable-nls --disable-x11 --disable-oss-wrapper --disable-alsa --disable-esound --disable-waveout --disable-glib2 --disable-gtk3 --disable-gconf --disable-avahi --disable-jack --disable-asyncns --disable-tcpwrap --disable-lirc --disable-dbus --disable-bluez --disable-udev --disable-openssl --disable-xen --disable-systemd --disable-manpages --disable-samplerate --without-speex --with-database=simple --disable-orc
# --enable-static-bins
make
make install
