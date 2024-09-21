#!/bin/bash

cd $( dirname -- "${BASH_SOURCE[0]}" )
SCRIPT_DIR=$(pwd)
WORK_DIR="$SCRIPT_DIR/download"
OUT_DIR="$SCRIPT_DIR/out"
export PREFIX="$SCRIPT_DIR/prefix"

export MAKEFLAGS="-j$(nproc)"
export EM_PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/
export EM_PKG_CONFIG_LIBDIR=$PREFIX/lib/
export PKG_CONFIG_LIBDIR=$PREFIX/lib/
export CHOST="wasm32-unknown-linux"
export CFLAGS="-s USE_PTHREADS"
export LDFLAGS="-lpthread"
export ax_cv_c_float_words_bigendian=no
export MESON_CROSS="$SCRIPT_DIR/emscripten-cross.txt"
export IPEPREFIX=/ipe
export EMSDK_KEEP_DOWNLOADS=1
export EMSDK="$WORK_DIR/emsdk"


mkdir -p $SCRIPT_DIR
mkdir -p $WORK_DIR
mkdir -p $OUT_DIR
mkdir -p $PKG_CONFIG_PATH

[ ! -f "$EMSDK/emsdk_env.sh" ] || source $EMSDK/emsdk_env.sh
