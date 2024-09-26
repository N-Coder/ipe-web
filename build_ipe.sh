#!/bin/bash

set -x
set -e

cd $( dirname -- "${BASH_SOURCE[0]}" )
source ./env.sh


## build ipe
cd $WORK_DIR
[ -d "ipe" ] || git clone https://github.com/N-Coder/ipe.git
cd ipe
git checkout ipe-web
[ -f "CMakeLists.txt" ] || ln -s $SCRIPT_DIR/CMakeLists.txt ./CMakeLists.txt
[ -f "src/ipelib/ipecurl_wasm.cpp" ] || ln -s $SCRIPT_DIR/ipecurl_wasm.cpp src/ipelib/
rm -rf install
mkdir -p install
cp -r src/ipe/lua install/lua
cp -r src/ipelets/lua install/ipelets
cp -r styles install/styles
cp -r artwork install/icons
$WORK_DIR/qt-wasm/qtbase/bin/qt-cmake . -DCMAKE_MODULE_PATH=$WORK_DIR/qt-wasm/qtbase/cmake
cmake --build . --verbose

mv ipe.html ipe.js ipe.wasm ipe.worker.js qtloader.js qtlogo.svg $OUT_DIR
