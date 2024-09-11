#!/bin/bash

set -x
set -e

cd $( dirname -- "${BASH_SOURCE[0]}" )
source ./env.sh


## install dependencies
apt-get update
apt-get install -y build-essential checkinstall curl git python3 python3-pip vim pkg-config autoconf libtool ccache
pip install --break-system-packages cmake meson ninja


## install emscripten
cd $WORK_DIR
[ -d "emsdk" ] || git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
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

## install gsl
cd $WORK_DIR
[ -d "gsl" ] || git clone git://git.savannah.gnu.org/gsl.git
cd gsl
git checkout release-2-8
emconfigure autoreconf -i
emconfigure ./configure --prefix=$PREFIX
emmake make
emmake make install

## install lua
cd $WORK_DIR
[ -f "lua-5.4.7.tar.gz" ] || curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
[ -d "lua-5.4.7" ] || tar zxf lua-5.4.7.tar.gz
cd lua-5.4.7
sed "s#INSTALL_TOP= /usr/local#INSTALL_TOP= $PREFIX#g" -i Makefile
sed "s#CC= gcc -std=gnu99#CC= emcc -std=gnu99#g" -i src/Makefile
sed "s#AR= ar rcu#AR= emar rcu#g" -i src/Makefile
sed "s#RANLIB= ranlib#RANLIB= emar s#g" -i src/Makefile
emmake make
emmake make install
# emmake make pc > $PREFIX/lib/pkgconfig/lua.pc
# echo -e '\nName: lua\nDescription: lua library\nVersion: 5.4.7\n' >> $PREFIX/lib/pkgconfig/lua.pc
# echo -e 'Requires:\nLibs: -L${libdir} -L${sharedlibdir} -llua\nCflags: -I${includedir}' >> $PREFIX/lib/pkgconfig/lua.pc

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
[ -d "qt-host" ] || tar xaf qt-everywhere-src-6.7.2.tar.xz
[ -d "qt-host" ] || mv qt-everywhere-src-6.7.2 qt-host
[ -d "qt-wasm" ] || cp -r qt-host qt-wasm
# once for the host tools
cd qt-host
./configure -prefix $PWD/qtbase
cmake --build . --parallel
# and once again cross compile the wasm library
cd ../qt-wasm
$EMSDK/emsdk install 3.1.50 # version required for QT 6.7 https://doc.qt.io/qt-6/wasm.html
$EMSDK/emsdk activate 3.1.50
source $EMSDK/emsdk_env.sh
./configure -qt-host-path ../qt-host/qtbase -platform wasm-emscripten -prefix $PREFIX -feature-thread # -system-zlib -qt-libjpeg -system-libpng -system-freetype
cmake --build . --parallel
# while ! installout=$(cmake --install . 2>&1 > /dev/null); do
#     echo $installout
#     line=$(echo "$installout" | grep " cmake_install.cmake:" | grep -Eo "[0-9]+")
#     echo $line
#     sed -i "$line s/^/#/" cmake_install.cmake
# done
cmake --install .

# cd
# cp ./qt-host/qtbase/lib/pkgconfig/Qt*.pc $PREFIX/lib/pkgconfig/
# sed "s#prefix=/root/qt-host/qtbase#prefix=$PREFIX#g" -i Qt*.pc
$EMSDK/emsdk install latest
$EMSDK/emsdk activate latest
source $EMSDK/emsdk_env.sh

embuilder build libjpeg

## install ipe
cd $WORK_DIR
[ -d "ipe" ] || git clone https://github.com/otfried/ipe.git
cd ipe
git checkout v7.2.30
cd src
sed "s#CXX = g++#CXX = em++ --use-port=libjpeg#g" -i config.mak
sed "s#LUA_PACKAGE   ?= lua5.4#LUA_PACKAGE   ?= lua#g" -i config.mak
sed "s#IPESRCDIR ?= ..#IPESRCDIR ?= .#g" -i common.mak
sed 's#moc_sources  = $(addprefix moc_, $(subst .h,.cpp,$(moc_headers)))#moc_sources  = $(subst /,/moc_,$(subst .h,.cpp,$(moc_headers)))#g' -i common.mak
sed "s#jpeg_read_header(&cinfo, 1);#jpeg_read_header(\&cinfo, TRUE);#g" -i ipelib/ipebitmap_unix.cpp
cp ./Makefile ./Makefile.bak
# emmake make all
# maybe add /root/prefix/lib/liblua.a manually to emcc invocation

cd ..
cp $SCRIPT_DIR/CMakeLists.txt .
$WORK_DIR/qt-wasm/qtbase/bin/qt-cmake .
cmake --build .

# emcc -o final.html -sFETCH ../build/lib/libipe.so ../build/obj/ipetoipe/ipetoipe.o  $PREFIX/lib/libgslcblas.a $PREFIX/lib/libgsl.a --emrun --embed-file schedule.ipe --proxy-to-worker

