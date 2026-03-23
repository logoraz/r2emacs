# Install Emacs using MSYS2

Get MSYS2 from https://github.com/msys2/msys2-installer/releases/

Then install to `C:\Users\<username>\AppData\Local\Programs\msys2`

## Update MSYS2 base environment


```bash
pacman -Syu
```

```bash
pacman -Su
```

To install the required packages for building Emacs:

```bash
pacman -Su \
  autoconf \
  autogen \
  automake \
  automake-wrapper \
  git \
  libidn-devel \
  libltdl \
  libnettle-devel \
  libopenssl \
  libp11-kit-devel \
  libtasn1-devel \
  libunistring \
  make \
  mingw-w64-ucrt-x86_64-toolchain \
  mingw-w64-ucrt-x86_64-bzip2 \
  mingw-w64-ucrt-x86_64-cairo \
  mingw-w64-ucrt-x86_64-crt-git \
  mingw-w64-ucrt-x86_64-expat \
  mingw-w64-ucrt-x86_64-fontconfig \
  mingw-w64-ucrt-x86_64-freetype \
  mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-gcc-libs \
  mingw-w64-ucrt-x86_64-gdk-pixbuf2 \
  mingw-w64-ucrt-x86_64-gettext \
  mingw-w64-ucrt-x86_64-giflib \
  mingw-w64-ucrt-x86_64-glib2 \
  mingw-w64-ucrt-x86_64-gmp \
  mingw-w64-ucrt-x86_64-gnutls \
  mingw-w64-ucrt-x86_64-harfbuzz \
  mingw-w64-ucrt-x86_64-headers-git \
  mingw-w64-ucrt-x86_64-imagemagick \
  mingw-w64-ucrt-x86_64-libgccjit \
  mingw-w64-ucrt-x86_64-libiconv \
  mingw-w64-ucrt-x86_64-libidn2 \
  mingw-w64-ucrt-x86_64-libjpeg-turbo \
  mingw-w64-ucrt-x86_64-libpng \
  mingw-w64-ucrt-x86_64-librsvg \
  mingw-w64-ucrt-x86_64-sqlite3 \
  mingw-w64-ucrt-x86_64-libtree-sitter \
  mingw-w64-ucrt-x86_64-libtiff \
  mingw-w64-ucrt-x86_64-libunistring \
  mingw-w64-ucrt-x86_64-libxml2 \
  mingw-w64-ucrt-x86_64-nettle \
  mingw-w64-ucrt-x86_64-p11-kit \
  mingw-w64-ucrt-x86_64-winpthreads \
  mingw-w64-ucrt-x86_64-xpm-nox \
  mingw-w64-ucrt-x86_64-xz \
  mingw-w64-ucrt-x86_64-zlib \
  mingw-w64-ucrt-x86_64-jbigkit \
  pkgconf \
  texinfo \
```

## Fetch Emacs source

```bash
git config --global core.autocrlf false
git clone https://github.com/emacs-mirror/emacs --depth 1
```

## Build Emacs

It is important to incluce `--with-gnutls`, since otherwise Emacs won't even be able to use ELPA outside MSYS2. Also, dbus is not
useful for Emacs on Windows. Also, imagemagick causes problems so I specify `--without-imagemagick` so that normal images work...

Set `prefix` to somewhere appropriate, in my use-case I install to `~/Works/builds/emacs-build/`

```bash
cd emacs
./autogen.sh
mkdir build
cd build
target=/c/Users/<username>/Work/builds/emacs-build
../configure prefix=$target \
    --with-native-compilation=aot \
    --with-gnutls \
    --without-dbus \
    --without-pop \
    --with-xpm \
    --without-imagemagick \
    --with-tree-sitter
```

Now build...

```bash
make -j 4 bootstrap
make install
```

Note: XPM Image requires `libXpm-noX4.dll`. Emacs can start without this DLL but then it won't be able to display XPM image. Also
`libtree-sitter.dll` depends on `wasmtime.dll`.

## DLL Hell

The easiest way is to copy all dlls from `/ucrt64/bin` and have a huge directory in the Emacs source directory...

```bash
cp /c/Users/<username>/AppData/Local/Programs/msys2/bin/*.dll /c/Users/<username>/AppData/Local/Programs/emacs/bin
```

### GCCJIT

Additional works are required to make native compile work without complete MSYS2 environment:

```bash
mkdir $target/lib/gcc
cp /ucrt64/lib/{crtbegin,crtend,dllcrt2}.o $target/lib/gcc
cp /ucrt64/lib/lib{advapi32,gcc_s,mingw32,msvcrt,shell32,kernel32,mingwex,pthread,user32}.a $target/lib/gcc
# adjust path according to gcc version
cp /ucrt64/lib/gcc/x86_64-w64-mingw32/15.2.0/libgcc.a $target/lib/gcc
cp /ucrt64/bin/{ld,as}.exe $target/lib/gcc
```

## Install on Windows

I install to `C:\Users\<username>\AppData\Local\Programs\emacs` and add to local PATH, i.e.
`%USERPROFILE%\AppData\Local\Programs\emacs\bin`


## References

LdBeth/build.org
- https://gist.github.com/LdBeth/d663a7d3ea27776bfe211241ad7fa5e5
