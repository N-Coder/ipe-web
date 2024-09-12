cmake_minimum_required(VERSION 3.16)

list(APPEND CMAKE_MODULE_PATH /root/qt-wasm/qtbase/cmake)

project(ipe VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets Svg)
qt_standard_project_setup()

add_compile_options("-sUSE_PTHREADS")
add_link_options("-lpthread" "-sUSE_PTHREADS")

qt_add_executable(ipe
    src/ipe/tools.cpp
    src/ipe/appui.cpp
    src/ipe/uilua.cpp
    src/ipe/main_qt.cpp
    src/ipe/appui_qt.cpp
    src/ipe/controls_qt.cpp
    src/ipecairo/ipecairopainter.cpp
    src/ipecairo/ipefonts.cpp
    src/ipecairo/ipethumbs.cpp
    src/ipecanvas/ipetool.cpp
    src/ipecanvas/ipecanvas.cpp
    src/ipecanvas/ipepdfview.cpp
    src/ipecanvas/ipecanvas_qt.cpp
    src/ipecanvas/ipeselector_qt.cpp
    src/ipecanvas/ipepdfview_qt.cpp
    src/ipeui/ipeui_common.cpp
    src/ipeui/ipeui_qt.cpp
    src/ipelib/ipebase.cpp
    src/ipelib/ipeplatform.cpp
    src/ipelib/ipegeo.cpp
    src/ipelib/ipexml.cpp
    src/ipelib/ipeattributes.cpp
    src/ipelib/ipebitmap.cpp
    src/ipelib/ipeshape.cpp
    src/ipelib/ipegroup.cpp
    src/ipelib/ipeimage.cpp
    src/ipelib/ipetext.cpp
    src/ipelib/ipepath.cpp
    src/ipelib/ipereference.cpp
    src/ipelib/ipeobject.cpp
    src/ipelib/ipefactory.cpp
    src/ipelib/ipestdstyles.cpp
    src/ipelib/ipeiml.cpp
    src/ipelib/ipepage.cpp
    src/ipelib/ipepainter.cpp
    src/ipelib/ipetoolbase.cpp
    src/ipelib/ipepdfparser.cpp
    src/ipelib/ipepdfwriter.cpp
    src/ipelib/iperesources.cpp
    src/ipelib/ipestyle.cpp
    src/ipelib/ipesnap.cpp
    src/ipelib/ipeutils.cpp
    src/ipelib/ipelatex.cpp
    src/ipelib/ipedoc.cpp
    src/ipelib/ipebitmap_unix.cpp
    src/ipelua/ipelib.cpp
    src/ipelua/ipeluageo.cpp
    src/ipelua/ipeluaobj.cpp
    src/ipelua/ipeluastyle.cpp
    src/ipelua/ipeluapage.cpp
    src/ipelua/ipeluaipelet.cpp
)

set(IPEVERS "7.2.30")
set(PREFIX "/root/prefix")
set(IPEPREFIX "$PREFIX/usr/local")

target_compile_definitions(ipe PRIVATE IPEUI_QT)
target_compile_definitions(ipe PRIVATE IPEBINDIR="$IPEPREFIX/bin")
target_compile_definitions(ipe PRIVATE IPELIBDIR="$IPEPREFIX/lib")
target_compile_definitions(ipe PRIVATE IPEHEADERDIR="$IPEPREFIX/include")
target_compile_definitions(ipe PRIVATE IPELETDIR="$IPEPREFIX/lib/ipe/$IPEVERS/ipelets")
target_compile_definitions(ipe PRIVATE IPELUADIR="$IPEPREFIX/share/ipe/$IPEVERS/lua")
target_compile_definitions(ipe PRIVATE IPESCRIPTDIR="$IPEPREFIX/share/ipe/$IPEVERS/scripts")
target_compile_definitions(ipe PRIVATE IPESTYLEDIR="$IPEPREFIX/share/ipe/$IPEVERS/styles")
target_compile_definitions(ipe PRIVATE IPEICONDIR="$IPEPREFIX/share/ipe/$IPEVERS/icons")
target_compile_definitions(ipe PRIVATE IPEDOCDIR="$IPEPREFIX/share/ipe/$IPEVERS/doc")
target_compile_definitions(ipe PRIVATE IPEMANDIR="$IPEPREFIX/share/man/man1")

target_include_directories(ipe PRIVATE /root/prefix/include/ /root/prefix/include/cairo /root/prefix/include/freetype2)
target_include_directories(ipe PRIVATE /root/emsdk/upstream/emscripten/cache/sysroot/include/)
target_include_directories(ipe PRIVATE src/include src/ipe src/ipecairo src/ipecanvas src/ipeui src/ipelib src/ipelua)
target_link_libraries(ipe PRIVATE Qt6::Widgets Qt6::Svg)

target_link_libraries(ipe PRIVATE /root/prefix/lib/libpng.a /root/prefix/lib/libz.a /root/prefix/lib/liblua.a /root/prefix/lib/libgsl.a /root/prefix/lib/libcairo.a /root/prefix/lib/libfreetype.a /root/prefix/lib/libspiro.a /root/prefix/lib/libpixman-1.a)