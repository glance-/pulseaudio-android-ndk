adb shell mkdir -p /data/local/pulse/bin/ /data/local/pulse/lib/
adb push ndk-x86_64/sysroot/usr/bin/pulseaudio /data/local/pulse/bin/pulseaudio
adb push ndk-x86_64/sysroot/usr/lib/pulseaudio/{libpulseco*so /data/local/pulse/lib/
adb push ndk-x86_64/sysroot/usr/lib/{libpulse.so,libsndfile.so,libltdl.so} /data/local/pulse/lib/
adb push ndk-x86_64/sysroot/usr/lib/pulse-12.99/modules /data/local/pulse/


adb shell env PULSE_RUNTIME_PATH=/data/local/pulse/tmp/ PULSE_STATE_PATH=/data/local/pulse/tmp/ LD_LIBRARY_PATH=/data/local/pulse/lib/:/data/local/pulse/modules /data/local/pulse/bin/pulseaudio -vvv -n --use-pid-file=no -p /data/local/pulse/modules -L module-sles-sink  -L "module-native-protocol-tcp auth-cookie-enabled=false port=4714 auth-ip-acl=127.0.0.1/8"
