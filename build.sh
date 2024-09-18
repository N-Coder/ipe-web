#!/bin/bash

set -x
set -e

cd $( dirname -- "${BASH_SOURCE[0]}" )
source ./env.sh


## install dependencies
apt-get update
apt-get install -y build-essential curl git python3 python3-pip pkg-config autoconf libtool ccache vim
pip install --break-system-packages cmake meson ninja


## install emscripten
cd $WORK_DIR
[ -d "emsdk" ] || git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install 3.1.50 # version required for QT 6.7 https://doc.qt.io/qt-6/wasm.html
./emsdk activate 3.1.50
source ./emsdk_env.sh


## install zlib
cd $WORK_DIR
[ -d "zlib" ] || git clone https://github.com/madler/zlib.git
cd zlib
git checkout v1.3.1
emconfigure ./configure --static --prefix=$PREFIX
emmake make
emmake make install

## install libpng
cd $WORK_DIR
[ -d "libpng" ] || git clone https://github.com/pnggroup/libpng.git
cd libpng
git checkout v1.6.43
sed 's/DEFAULT_INCLUDES = .*/DEFAULT_INCLUDES = -I.@am__isrc@ ${CCASFLAGS}/' -i Makefile.in
emconfigure ./configure --host=${CHOST} --with-binconfigs=no --prefix=$PREFIX --enable-shared=no --disable-dependency-tracking \
    CFLAGS="$(pkg-config --cflags zlib) $CFLAGS" \
    LDFLAGS="$(pkg-config --libs zlib) $LDFLAGS" \
    --with-pkgconfigdir=$PREFIX/lib/pkgconfig/ --with-zlib-prefix=$PREFIX
emmake make
emmake make install

## install libjpeg-turbo
# cd $WORK_DIR
# [ -d "libjpeg-turbo" ] || git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
# cd libjpeg-turbo
# git checkout 3.0.3
# [ -d "build" ] || mkdir build
# cd build
# emmake cmake -G"Unix Makefiles" -DCMAKE_SIZEOF_VOID_P=8 -DCMAKE_INSTALL_PREFIX=$PREFIX ..
# emmake make
# emmake make install
embuilder build libjpeg

## install gsl
cd $WORK_DIR
[ -d "gsl" ] || git clone git://git.savannah.gnu.org/gsl.git
cd gsl
git checkout release-2-8
emconfigure autoreconf -i
emconfigure ./configure --prefix=$PREFIX
emmake make LDFLAGS="$LDFLAGS -all-static" # https://stackoverflow.com/a/67169806
emmake make install

## install lua
cd $WORK_DIR
[ -f "lua-5.4.7.tar.gz" ] || curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
[ -d "lua-5.4.7" ] || tar zxf lua-5.4.7.tar.gz
cd lua-5.4.7
sed "s#INSTALL_TOP= /usr/local#INSTALL_TOP= $PREFIX#g" -i Makefile
sed "s#CC= gcc -std=gnu99#CC= emcc -std=gnu99 $CFLAGS#g" -i src/Makefile
sed "s#AR= ar rcu#AR= emar rcu#g" -i src/Makefile
sed "s#RANLIB= ranlib#RANLIB= emar s#g" -i src/Makefile
emmake make
emmake make install

## install libspiro
cd $WORK_DIR
[ -d "libspiro" ] || git clone https://github.com/fontforge/libspiro.git
cd libspiro
git checkout 20240903
emconfigure autoreconf -i
emconfigure automake --foreign -Wall
emconfigure ./configure --prefix=$PREFIX
emmake make
emmake make install

## install freetype
cd $WORK_DIR
[ -d "freetype" ] || git clone https://gitlab.freedesktop.org/freetype/freetype.git
cd freetype
git checkout VER-2-13-3
meson setup _build --prefix=$PREFIX --cross-file=$MESON_CROSS --default-library=static --buildtype=release -Dtests=disabled --wrap-mode=nofallback
meson install -C _build

## install pixman
cd $WORK_DIR
[ -d "pixman" ] || git clone https://gitlab.freedesktop.org/pixman/pixman.git
cd pixman
git checkout pixman-0.43.4
meson setup _build --prefix=$PREFIX --cross-file=$MESON_CROSS --default-library=static --buildtype=release -Dtests=disabled --wrap-mode=nofallback
meson install -C _build

## install cairo
cd $WORK_DIR
[ -d "cairo" ] || git clone https://gitlab.freedesktop.org/cairo/cairo.git
cd cairo
git checkout 1.17.8
meson setup _build --prefix=$PREFIX --cross-file=$MESON_CROSS --default-library=static --buildtype=release -Dtests=disabled --wrap-mode=nofallback
meson install -C _build

## install qt-wasm
cd $WORK_DIR
[ -f "qt-everywhere-src-6.7.2.tar.xz" ] || curl -L -R -O https://download.qt.io/official_releases/qt/6.7/6.7.2/single/qt-everywhere-src-6.7.2.tar.xz
[ -d "qt-everywhere-src-6.7.2" ] || tar xaf qt-everywhere-src-6.7.2.tar.xz
rm -rf qt-everywhere-src-6.7.2/qtwebengine
[ -d "qt-host" ] || cp -r qt-everywhere-src-6.7.2 qt-host
[ -d "qt-wasm" ] || cp -r qt-everywhere-src-6.7.2 qt-wasm
# once for the host tools
cd qt-host
CFLAGS="" LDFLAGS="" ./configure -prefix $PWD/qtbase -no-opengl
CFLAGS="" LDFLAGS="" cmake --build . -t qtbase -t qtdeclarative -t lrelease --parallel

# and once again cross compile the wasm library
cd ../qt-wasm
./configure -qt-host-path ../qt-host/qtbase -platform wasm-emscripten -prefix $PREFIX -feature-thread # -system-zlib -qt-libjpeg -system-libpng -system-freetype
cmake --build . --parallel
cmake --install .


## build ipe
$SCRIPT_DIR/build_ipe.sh
