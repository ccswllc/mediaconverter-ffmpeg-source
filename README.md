# MediaConverter: FFmpeg source

The complete corresponding source of the FFmpeg libraries in **MediaConverter**
for iPhone and iPad (CCSW LLC, bundle `com.ccswllc.mediaconverter`), offered
under the GNU Lesser General Public License 3.0. The app's
*Open-Source Licenses* screen points here.

The app links FFmpeg **dynamically**: `libavcodec`, `libavformat`,
`libavfilter`, `libavutil`, `libswscale`, `libswresample`, `libavdevice` and
`ffmpegkit` ship as separate frameworks inside the app, so they can be
replaced with a build of your own. FFmpeg is configured with
`--enable-version3` and **without** `--enable-gpl` or `--enable-nonfree`, so the
build is LGPL 3.0.

This first build serves MediaConverter 1.0 and on, until a release notes a
different FFmpeg build here.

## What is here

| Path | What |
|---|---|
| `ffmpeg-kit-next/` | [arthenica/ffmpeg-kit-next](https://github.com/arthenica/ffmpeg-kit-next) at tag `v9.0.0` (commit `a724ed99583dcfe2af497c794fdd6b24ddd54a4e`): the build scripts and the `ffmpegkit` wrapper (LGPL 3.0) |
| `libraries/<name>/` | the source of each library at the exact commit built, as `git archive` of that commit |
| `patches/<name>.diff` | the edits ffmpeg-kit-next's scripts make inside a library's tree during the build, captured afterwards (see below) |
| `build/build-ffmpeg.sh` | the script that drove the build, with the exact `ios.sh` flags |
| `build/BUILD-INFO.md` | toolchain, flags, versions and output |
| `build/ffmpeg-configuration.txt` | FFmpeg's configure line as compiled into `libavutil` (arm64 device), i.e. `avutil_configuration()` |
| `build/libraries.tsv` | library, tag, commit, upstream remote |

| Library | Tag | Commit | Fetched from | License |
|---|---|---|---|---|
| FFmpeg | `n9.0.1` | `bf1b838f2ab88b4f8fd83443325c782ea0e0f7fa` | github.com/arthenica/FFmpeg | LGPL 3.0 (as configured) |
| LAME | `RELEASE__3_100` | `b8f6b9e0fdbfb6fecfc106e8d24af240eac44b22` | github.com/arthenica/lame | LGPL 2.0 or later |
| libogg | `v1.3.6` | `be05b13e98b048f0b5a0f5fa8ce514d56db5f822` | github.com/arthenica/ogg | BSD 3-clause |
| libvorbis | `v1.3.7` | `0657aee69dec8508a0011f47f3b69d7538e9d262` | github.com/arthenica/vorbis | BSD 3-clause |
| libwebp | `v1.6.0` | `4fa21912338357f89e4fd51cf2368325b59e9bd9` | github.com/arthenica/libwebp | BSD 3-clause |
| Opus | `v1.5.2` | `ddbe48383984d56acd9e1ab6a090c54ca6b735a6` | github.com/arthenica/opus | BSD 3-clause |
| dav1d | `1.5.3` | `b546257f770768b2c88258c533da38b91a06f737` | github.com/arthenica/dav1d | BSD 2-clause |
| libaom | `v3.12.1` | `10aece4157eb79315da205f39e19bf6ab3ee30d0` | github.com/arthenica/libaom | BSD 2-clause + AOM patent license |

zlib, bzip2, libiconv, VideoToolbox and AudioToolbox are Apple's system
libraries and are not part of this source.

## The in-tree edits (`patches/`)

ffmpeg-kit-next's `scripts/apple/<library>.sh` edit a library's tree before
configuring it. Those scripts are in `ffmpeg-kit-next/`, so building from this
repository repeats the edits; the diffs show what they are:

- `ffmpeg.diff`: `scripts/apple/ffmpeg.sh` appends ffmpeg-kit's `ffkitmem` and
  `ffkitstream` protocols (from `ffmpeg-kit-next/tools/protocols/`) to
  `libavformat/file.c` and `libavutil/file.c` and registers them, makes
  `av_log_level` thread-local, drops `-mdynamic-no-pic`, and links the
  libraries as frameworks in `ffbuild/common.mak`. The edits are made once per
  architecture; the diff shows the tree after the last one built (the
  framework path in `common.mak` names that architecture).
- `libvorbis.diff`: `scripts/apple/libvorbis.sh` removes `-mno-ieee-fp`, which
  clang does not accept.
- `lame.diff`: the files `autoreconf` regenerates in `scripts/apple/lame.sh`;
  no hand edit.

## Rebuilding

On macOS with Xcode 26 (the build used Xcode 26.3, iOS SDK 26.2) and the
Homebrew tools listed at the top of `build/build-ffmpeg.sh`:

1. Copy each `libraries/<name>/` to `ffmpeg-kit-next/src/<name>/`.
2. From `ffmpeg-kit-next/`, run the `./ios.sh …` line in
   `build/BUILD-INFO.md` (the same flags as `BUILD_FLAGS` in
   `build/build-ffmpeg.sh`), with the environment that script exports.
3. The xcframeworks are in
   `ffmpeg-kit-next/prebuilt/bundle-apple-xcframework-ios-18.0/`.

To use a modified FFmpeg with MediaConverter, replace the frameworks inside
the app bundle with your build and re-sign it.

## Licenses

Each library's own license files are in its folder; the LGPL 3.0 and GPL 3.0
texts are in `ffmpeg-kit-next/LICENSE` and `libraries/ffmpeg/COPYING.LGPLv3`,
`libraries/ffmpeg/COPYING.GPLv3`. MediaConverter itself is not open source;
this repository covers only the libraries above.

FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.
Questions: info@ccswllc.com.
