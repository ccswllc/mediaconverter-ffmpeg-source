# FFmpegKit build

The LGPL ffmpeg behind `FFmpegEngine` (`docs/todo-feat-ffmpeg-engine.md`).
The binaries in this folder are gitignored; `Tools/build-ffmpeg.sh` rebuilds
them, running every third-party script as the `build` user, and refuses a
build whose configuration holds `--enable-gpl` or `--enable-nonfree`.

## Source

- [arthenica/ffmpeg-kit-next](https://github.com/arthenica/ffmpeg-kit-next) at tag **v9.0.0**
  (the wrapper is LGPL 3.0; ffmpeg is configured with `--enable-version3`, so the
  whole build is LGPL 3.0).
- Built 2026-10-02 with Xcode 26.3 (iOS SDK 26.2) on an Intel Mac, through
  Homebrew tools rather than the repository's Nix shell.

## Flags

```
./ios.sh -x --spm --target=18.0 --arch=arm64,arm64-simulator,x86-64 \
  --enable-lib-ios-videotoolbox --enable-lib-ios-audiotoolbox \
  --enable-lib-ios-zlib --enable-lib-ios-bzip2 \
  --enable-lib-lame --enable-lib-opus --enable-lib-libvorbis \
  --enable-lib-libwebp --enable-lib-dav1d --enable-lib-libaom \
  --disable-lib-giflib --disable-lib-jpeg --disable-lib-libpng --disable-lib-tiff
```

No `--enable-gpl`, so no x264, x265, vidstab, rubberband or xvid. libiconv
comes in as a dependency (Apple's system library).

## Libraries

| Library | Version |
|---|---|
| FFmpeg | n9.0.1 |
| lame | 3.100 |
| opus | 1.5.2 |
| libvorbis / libogg | 1.3.7 / 1.3.6 |
| libwebp | 1.6.0 |
| dav1d | 1.5.3 |
| libaom | 3.12.1 |

## Output

Dynamic xcframeworks, iOS 18.0: device `ios-arm64`, simulator
`ios-arm64_x86_64-simulator`. Device slice sizes: libavcodec 14 MB,
libavfilter 2.4 MB, libavformat 2.1 MB, ffmpegkit 0.7 MB, libswscale 0.6 MB,
libavutil 0.6 MB, libswresample 0.1 MB, libavdevice 0.1 MB; about 20 MB in the
app's Frameworks folder.

## ffmpeg configuration (arm64)

`avutil_configuration()`, as compiled in; `FFmpegEngineTests.libraryIsNotGPL`
checks it at run time.

```
--cross-prefix=arm64-ios-darwin- 
--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPho
neOS26.2.sdk --prefix=/Users/build/src/ffmpeg-kit-next/prebuilt/apple-ios-arm64-18.0/ffmpeg 
--pkg-config=/Users/build/tools/venv/bin/pkg-config --enable-version3 --arch=aarch64 --cpu=armv8 
--target-os=darwin --enable-neon --enable-asm 
--ar=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar 
--cc=clang --cxx=clang++ --as='/Users/build/src/ffmpeg-kit-next/.tmp/gas-preprocessor.pl -arch 
aarch64 -- clang -arch arm64 -target arm64-apple-ios18.0 -march=armv8-a+crc+crypto -mcpu=generic 
-DFFMPEG_KIT_ARM64 -Wno-unused-function -Wno-deprecated-declarations -fstrict-aliasing 
-fembed-bitcode -DIOS -DFFMPEG_KIT_MIN_SDK=18.0 -DFFMPEG_KIT_BUILD_DATE=20261002 
-DUSES_FFMPEG_KIT_PROTOCOLS -Wno-incompatible-function-pointer-types -isysroot 
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.s
dk -Oz -miphoneos-version-min=18.0 
-I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2
.sdk/usr/include' 
--ranlib=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranl
ib 
--strip=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip
 --nm=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm 
--extra-ldflags='-miphoneos-version-min=18.0' --disable-autodetect --enable-cross-compile 
--enable-pic --enable-inline-asm --enable-optimizations --enable-swscale --enable-shared 
--disable-static --install-name-dir='@rpath' --enable-pthreads --disable-v4l2-m2m 
--disable-outdev=v4l2 --disable-outdev=fbdev --disable-indev=v4l2 --disable-indev=fbdev 
--enable-small --disable-xmm-clobber-test --disable-debug --disable-neon-clobber-test 
--disable-programs --disable-doc --disable-htmlpages --disable-manpages --disable-podpages 
--disable-txtpages --disable-sndio --disable-schannel --disable-securetransport --disable-xlib 
--disable-cuda --disable-cuvid --disable-nvenc --disable-vaapi --disable-vdpau --disable-alsa 
--disable-cuda --disable-cuvid --disable-nvenc --disable-vaapi --disable-vdpau --enable-libmp3lame 
--enable-libvorbis --enable-libwebp --enable-libdav1d --enable-libopus --enable-libaom 
--disable-sdl2 --disable-openssl --enable-zlib --enable-audiotoolbox --disable-outdev=audiotoolbox 
--enable-bzlib --enable-videotoolbox --disable-filter=scale_vt --disable-avfoundation 
--enable-iconv --disable-coreimage --disable-appkit --disable-opencl --disable-opengl
```
