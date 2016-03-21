pulseaudio-android-ndk
======================

Scripts and patches to cross compile pulseaudio with android ndk


Why?
====
My plan was to build a android app which ran pulseaudio against local
sinks and sources, to be able to use it as a headset. I sort of ran out
of time and just started to sketch out a opensl sink in pulseaudio, and
didn't get any further.


How to update patches?
======================
pulseaudio$ git format-patch -o ../patches/ origin/master..
