#!/bin/bash

set -x
set -e

cd $( dirname -- "${BASH_SOURCE[0]}" )
source ./env.sh


## build ipe
cd $WORK_DIR
[ -d "ipe" ] || git clone https://github.com/otfried/ipe.git
cd ipe
git checkout v7.2.30
sed "s#jpeg_read_header(&cinfo, 1);#jpeg_read_header(\&cinfo, TRUE);#g" -i src/ipelib/ipebitmap_unix.cpp
sed "s#Platform::runLatex#Platform::runLatexNative#g" -i src/ipelib/ipeplatform.cpp
sed "s#static int runLatex#static int runLatexNative(String dir, LatexType engine, String docname) noexcept;static int runLatex#g" -i src/include/ipebase.h
ln $SCRIPT_DIR/CMakeLists.txt ./CMakeLists.txt || true
ln $SCRIPT_DIR/ipecurl_wasm.cpp src/ipelib/ || true
mkdir -p install
cp -r src/ipe/lua install/lua
cp -r src/ipelets/lua install/ipelets
cp -r styles install/styles
cp -r artwork install/icons
$WORK_DIR/qt-wasm/qtbase/bin/qt-cmake . -DCMAKE_MODULE_PATH=$WORK_DIR/qt-wasm/qtbase/cmake
cmake --build . --verbose
