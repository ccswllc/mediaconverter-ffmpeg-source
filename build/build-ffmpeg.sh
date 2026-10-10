#!/bin/zsh
# Builds the LGPL FFmpegKit xcframeworks the FFmpegEngine links, from
# arthenica/ffmpeg-kit-next at a pinned tag, and copies them into
# Vendor/FFmpegKit/. See docs/todo-feat-ffmpeg-engine.md and
# Vendor/FFmpegKit/BUILD-INFO.md.
#
# Usage: Tools/build-ffmpeg.sh            # tools, build, copy
#        Tools/build-ffmpeg.sh --copy     # copy an earlier build only
#
# **Third-party code runs as the `build` user**, never as you: the clone, its
# build scripts, every library's configure/make, and the helper tools built
# from source. `build` cannot read your home; it writes to $OUT, and this
# script copies from there into the repository as you. Needs a sudoers rule
# letting you become `build` without a password (`sudo -n`); without one it
# stops rather than building as you.
#
# Host tools come from Homebrew, installed as you (/usr/local on Intel):
#   brew install autoconf libtool cmake nasm yasm gnu-sed bison gettext
# automake, pkg-config, meson and ninja are not bottled for Intel Sequoia and
# Homebrew refuses to build them without the Command Line Tools, so `build`
# makes its own in $TOOLS (pip wheels and the GNU automake tarball). With the
# CLT installed, `brew install automake pkg-config meson ninja` would replace
# that step.
#
# Licensing: no --enable-gpl and no GPL or nonfree library. The script refuses
# to copy a build whose ffmpeg configuration says otherwise.

set -euo pipefail

TAG=v9.0.0
REPO=https://github.com/arthenica/ffmpeg-kit-next.git
SRC=/Users/build/src/ffmpeg-kit-next
TOOLS=/Users/build/tools
OUT=/Users/Shared/build-out/ffmpeg-kit-$TAG
AUTOMAKE_VERSION=1.18.1
PKG_M4_URL=https://raw.githubusercontent.com/pkgconf/pkgconf/pkgconf-2.5.1/pkg.m4

# iOS 18 matches the app's deployment target. Device arm64; simulator x86_64
# (Intel Macs) and arm64 (Apple Silicon). No arm64e or Mac Catalyst.
BUILD_FLAGS=(
  -x --spm
  --target=18.0
  --arch=arm64,arm64-simulator,x86-64
  --enable-lib-ios-videotoolbox
  --enable-lib-ios-audiotoolbox
  --enable-lib-ios-zlib
  --enable-lib-ios-bzip2
  --enable-lib-lame
  --enable-lib-opus
  --enable-lib-libvorbis
  --enable-lib-libwebp
  --enable-lib-dav1d
  --enable-lib-libaom
  # libwebp pulls these in for its command-line tools only; ffmpeg's WebP
  # encoder needs none of them. libpng's configure also fails on an Intel
  # host (its preprocessor check runs `clang -E` for the host arch against
  # the device SDK's headers).
  --disable-lib-giflib
  --disable-lib-jpeg
  --disable-lib-libpng
  --disable-lib-tiff
)

REPO_ROOT=${0:A:h:h}
DEST=$REPO_ROOT/Vendor/FFmpegKit

as_build() { sudo -n -u build -H zsh -c "$1"; }

if ! sudo -n -u build true 2>/dev/null; then
  echo "error: cannot become 'build' without a password (sudo -n -u build)." >&2
  echo "Not building as $(whoami); fix the sudoers rule first." >&2
  exit 1
fi

if [[ ${1:-} != --copy ]]; then
  for t in /usr/local/bin/gsed /usr/local/opt/bison/bin/bison /usr/local/bin/glibtoolize \
           /usr/local/bin/autoreconf /usr/local/bin/cmake /usr/local/bin/nasm /usr/local/bin/yasm \
           /usr/local/bin/autopoint; do
    [[ -x $t ]] || { echo "error: missing $t; see the Homebrew line in this script's header." >&2; exit 1; }
  done

  # Helper tools, as `build`, into $TOOLS.
  as_build "
    set -euo pipefail
    mkdir -p $TOOLS/aclocal && cd $TOOLS
    [[ -x venv/bin/ninja ]] || { /usr/local/bin/python3 -m venv venv && venv/bin/pip install -q meson ninja pkgconf; }
    if [[ ! -x automake/bin/automake ]]; then
      curl -fsSLO https://ftp.gnu.org/gnu/automake/automake-$AUTOMAKE_VERSION.tar.xz
      tar xf automake-$AUTOMAKE_VERSION.tar.xz
      (cd automake-$AUTOMAKE_VERSION && PATH=/usr/local/bin:\$PATH ./configure --prefix=$TOOLS/automake >/dev/null && make >/dev/null && make install >/dev/null)
    fi
    [[ -f aclocal/pkg.m4 ]] || curl -fsSL -o aclocal/pkg.m4 $PKG_M4_URL
  "

  # Source at the pinned tag, as `build`.
  as_build "
    set -euo pipefail
    [[ -d $SRC/.git ]] || git clone $REPO $SRC
    cd $SRC && git fetch --tags -q && git -c advice.detachedHead=false checkout -q $TAG
  "

  # The build, as `build`. The environment mirrors flake.nix's toolchain hook:
  # GNU sed, Homebrew bison and libtoolize, meson, and an ACLOCAL_PATH holding
  # gettext's macros (Homebrew keeps them in share/gettext/m4, Nix in
  # share/aclocal) plus pkg.m4, libtool's and our own automake's.
  as_build "
    set -euo pipefail
    cd $SRC
    export PATH=$TOOLS/venv/bin:$TOOLS/automake/bin:/usr/local/opt/bison/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
    export SED=/usr/local/bin/gsed
    export BISON=/usr/local/opt/bison/bin/bison
    export LIBTOOLIZE=/usr/local/bin/glibtoolize
    export MESON=$TOOLS/venv/bin/meson
    export ACLOCAL_PATH=$TOOLS/aclocal:/usr/local/share/aclocal:/usr/local/opt/gettext/share/aclocal:/usr/local/opt/gettext/share/gettext/m4
    unset SDKROOT MACOSX_DEPLOYMENT_TARGET PKG_CONFIG_PATH
    ./ios.sh ${BUILD_FLAGS[*]}
    rm -rf $OUT && mkdir -p $OUT
    rsync -a prebuilt/bundle-apple-xcframework-ios-18.0/ $OUT/xcframeworks/
    cp build.log $OUT/build.log
    # avutil_configuration(), the configure line compiled into the library.
    strings $OUT/xcframeworks/libavutil.xcframework/ios-arm64/libavutil.framework/libavutil \
      | grep -m1 -- --cross-prefix > $OUT/ffmpeg-configuration.txt
  "
fi

# Copy into the repository, as you.
[[ -d $OUT/xcframeworks ]] || { echo "error: no build at $OUT" >&2; exit 1; }
if [[ ! -s $OUT/ffmpeg-configuration.txt ]] || grep -q -e --enable-gpl -e --enable-nonfree $OUT/ffmpeg-configuration.txt; then
  echo "error: $OUT has no configuration string, or one with --enable-gpl or --enable-nonfree; refusing it." >&2
  exit 1
fi
mkdir -p $DEST
find $DEST -mindepth 1 -maxdepth 1 ! -name BUILD-INFO.md -exec rm -rf {} +
rsync -a $OUT/xcframeworks/ $DEST/
echo "FFmpegKit $TAG copied to $DEST"
cat $OUT/ffmpeg-configuration.txt
