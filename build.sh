if [ ! -e ndk-arm ] ; then
	 ../android-ndk-r9/build/tools/make-standalone-toolchain.sh --install-dir=ndk-arm --platform=android-14
 fi
export BUILDROOT=$PWD
export PATH=${BUILDROOT}/ndk-arm/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-arm/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

git submodule update

if [ ! -e $PKG_CONFIG_PATH/json.pc ] ; then
cd json-c
./autogen.sh
./configure --build=arm-linux-androideabi --prefix=${PREFIX}
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
cd libsndfile-1.0.25
cp ../json-c/config.sub Cfg/
./configure --build=arm-linux-androideabi --prefix=${PREFIX}
make
make install
cd ..

cd pulseaudio
./autogen.sh
./configure --build=arm-linux-androideabi --prefix=${PREFIX}
make
make install
