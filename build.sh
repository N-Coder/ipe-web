#!/bin/bash

set -x
set -e

cd $( dirname -- "${BASH_SOURCE[0]}" )
SCRIPT_DIR=$(pwd)

export PREFIX=$SCRIPT_DIR/prefix
echo $PREFIX

export MAKEFLAGS="-j$(nproc)"
export EM_PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/
export EM_PKG_CONFIG_LIBDIR=$PREFIX/lib/
export PKG_CONFIG_LIBDIR=$PREFIX/lib/
export CHOST="wasm32-unknown-linux"
export ax_cv_c_float_words_bigendian=no
export MESON_CROSS="$SCRIPT_DIR/emscripten-cross.txt"
export IPEPREFIX=$PREFIX/usr/local
export EMSDK_KEEP_DOWNLOADS=1


mkdir -p $PKG_CONFIG_PATH


## install dependencies
apt-get update
apt-get install -y build-essential checkinstall curl git python3 python3-pip vim pkg-config autoconf libtool ccache
pip install --break-system-packages cmake meson ninja


## install emscripten
cd
[ -d "emsdk" ] || git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh


## install zlib
cd
[ -d "zlib" ] || git clone https://github.com/madler/zlib.git
cd zlib
git checkout v1.3.1
emconfigure ./configure --static --prefix=$PREFIX
emmake make
emmake make install

## install libpng
cd
[ -d "libpng" ] || git clone https://github.com/pnggroup/libpng.git
cd libpng
git checkout v1.6.43
sed 's/DEFAULT_INCLUDES = .*/DEFAULT_INCLUDES = -I.@am__isrc@ ${CCASFLAGS}/' -i Makefile.in
emconfigure ./configure --host=${CHOST} --with-binconfigs=no --prefix=$PREFIX --enable-shared=no --disable-dependency-tracking \
    CFLAGS="$(pkg-config --cflags zlib) -s USE_PTHREADS" \
    LDFLAGS="$(pkg-config --libs zlib) -lpthread" \
    --with-pkgconfigdir=$PREFIX/lib/pkgconfig/ --with-zlib-prefix=$PREFIX
emmake make
emmake make install

## install gsl
cd
[ -d "gsl" ] || git clone git://git.savannah.gnu.org/gsl.git
cd gsl
git checkout release-2-8
emconfigure autoreconf -i
emconfigure ./configure --prefix=$PREFIX
emmake make LDFLAGS=-all-static # https://stackoverflow.com/a/67169806
emmake make install

## install lua
cd
[ -f "lua-5.4.7.tar.gz" ] || curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
[ -d "lua-5.4.7" ] || tar zxf lua-5.4.7.tar.gz
cd lua-5.4.7
sed "s#INSTALL_TOP= /usr/local#INSTALL_TOP= $PREFIX#g" -i Makefile
sed "s#CC= gcc -std=gnu99#CC= emcc -std=gnu99#g" -i src/Makefile
sed "s#AR= ar rcu#AR= emar rcu#g" -i src/Makefile
sed "s#RANLIB= ranlib#RANLIB= emar s#g" -i src/Makefile
emmake make
emmake make install
emmake make pc > $PREFIX/lib/pkgconfig/lua.pc
echo -e '\nName: lua\nDescription: lua library\nVersion: 5.4.7\n' >> $PREFIX/lib/pkgconfig/lua.pc
echo -e 'Requires:\nLibs: -L${libdir} -L${sharedlibdir} -llua\nCflags: -I${includedir}' >> $PREFIX/lib/pkgconfig/lua.pc

## install libspiro
cd
[ -d "libspiro" ] || git clone https://github.com/fontforge/libspiro.git
cd libspiro
git checkout 20240903
emconfigure autoreconf -i
emconfigure automake --foreign -Wall
emconfigure ./configure --prefix=$PREFIX
emmake make
emmake make install

## install freetype
cd
[ -d "freetype" ] || git clone https://gitlab.freedesktop.org/freetype/freetype.git
cd freetype
git checkout VER-2-13-3
CFLAGS="-s USE_PTHREADS" \
LDFLAGS="-lpthread" \
    meson setup _build --prefix=$PREFIX --cross-file=$MESON_CROSS --default-library=static --buildtype=release -Dtests=disabled --wrap-mode=nofallback
meson install -C _build

## install pixman
cd
[ -d "pixman" ] || git clone https://gitlab.freedesktop.org/pixman/pixman.git
cd pixman
git checkout pixman-0.43.4
CFLAGS="-s USE_PTHREADS" \
LDFLAGS="-lpthread" \
    meson setup _build --prefix=$PREFIX --cross-file=$MESON_CROSS --default-library=static --buildtype=release -Dtests=disabled --wrap-mode=nofallback
meson install -C _build

## install cairo
cd
[ -d "cairo" ] || git clone https://gitlab.freedesktop.org/cairo/cairo.git
cd cairo
git checkout 1.17.8
CFLAGS="-s USE_PTHREADS" \
LDFLAGS="-lpthread" \
    meson setup _build --prefix=$PREFIX --cross-file=$MESON_CROSS --default-library=static --buildtype=release -Dtests=disabled --wrap-mode=nofallback
meson install -C _build

## install qt-wasm
cd
[ -f "qt-everywhere-src-6.7.2.tar.xz" ] || curl -L -R -O https://download.qt.io/official_releases/qt/6.7/6.7.2/single/qt-everywhere-src-6.7.2.tar.xz
[ -d "qt-host" ] || tar xaf qt-everywhere-src-6.7.2.tar.xz
[ -d "qt-host" ] || mv qt-everywhere-src-6.7.2 qt-host
[ -d "qt-wasm" ] || cp -r qt-host qt-wasm
# once for the host tools
cd qt-host
./configure -prefix $PWD/qtbase
cmake --build . -t qtbase --parallel
# and once again cross compile the wasm library
cd ../qt-wasm
~/emsdk/emsdk install 3.1.50 # version required for QT 6.7 https://doc.qt.io/qt-6/wasm.html
~/emsdk/emsdk activate 3.1.50
source ~/emsdk/emsdk_env.sh
./configure -qt-host-path ../qt-host/qtbase -platform wasm-emscripten -prefix $PREFIX # -system-zlib -qt-libjpeg -system-libpng -system-freetype
cmake --build . -t qtbase -t qtsvg -t Gui -t Widgets --parallel
while ! installout=$(cmake --install . 2>&1 > /dev/null); do
    echo $installout
    line=$(echo "$installout" | grep " cmake_install.cmake:" | grep -Eo "[0-9]+")
    echo $line
    sed -i "$line s/^/#/" cmake_install.cmake
done
cmake --install .

cd
cp ./qt-host/qtbase/lib/pkgconfig/Qt*.pc $PREFIX/lib/pkgconfig/
sed "s#prefix=/root/qt-host/qtbase#prefix=$PREFIX#g" -i Qt*.pc
~/emsdk/emsdk install latest
~/emsdk/emsdk activate latest
source ~/emsdk/emsdk_env.sh

## install ipe
cd
[ -d "ipe" ] || git clone https://github.com/otfried/ipe.git
cd ipe
git checkout v7.2.30
cd src
sed "s#CXX = g++#CXX = em++ --use-port=libjpeg#g" -i config.mak
sed "s#LUA_PACKAGE   ?= lua5.4#LUA_PACKAGE   ?= lua#g" -i config.mak
sed "s#IPESRCDIR ?= ..#IPESRCDIR ?= .#g" -i common.mak
sed 's#moc_sources  = $(addprefix moc_, $(subst .h,.cpp,$(moc_headers)))#moc_sources  = $(subst /,/moc_,$(subst .h,.cpp,$(moc_headers)))#g' -i common.mak
sed "s#jpeg_read_header(&cinfo, 1);#jpeg_read_header(\&cinfo, TRUE);#g" -i ipelib/ipebitmap_unix.cpp
mv ./Makefile ./Makefile.bak
cd $SCRIPT_DIR/ipe-Makefile ./Makefile
emmake make all
# maybe add /root/prefix/lib/liblua.a manually to emcc invocation

# emcc -o final.html -sFETCH ../build/lib/libipe.so ../build/obj/ipetoipe/ipetoipe.o  $PREFIX/lib/libgslcblas.a $PREFIX/lib/libgsl.a --emrun --embed-file schedule.ipe --proxy-to-worker