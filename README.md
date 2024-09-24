# ipe-web

This repository contains a script to build an HTML5 webassembly version of the [ipe editor](https://ipe.otfried.org/) via [emscripten](https://emscripten.org/).
You can try the resulting web app at [ipe.n-coder.de](https://ipe.n-coder.de/ipe.html).
While most of ipe already works, some parts (uploading/downloading files, ipelets, changing preferences...) are still work in progress.
Furthermore, the software should be considered alpha-level, so there may be still be broken functionalities or even crashes.

[![A screenshot of ipe in a browser](screenshot.png)](https://ipe.n-coder.de/ipe.html)

The build script is targeted at a current Debian (while the resulting webassembly is of course system independent); it is recommended to run it inside a Debian docker container or VM.
Note that running this script will take quite some time (about 2h on my laptop) and will generate roughly 30GB of data, mostly due to the two required [Qt 6 builds](https://doc.qt.io/qt-6/wasm.html).
You can abort the script at any point and restart while re-using most of the previous results.

You will find the build results in the `download/ipe` folder and can also download a precompiled version from the [releases section](https://github.com/N-Coder/ipe-web/releases) of this repo.
See the notes on running Qt6 WebAssembly code [here](https://doc.qt.io/qt-6/wasm.html#running-applications) and the blue box at the top of [this site](https://emscripten.org/docs/porting/pthreads.html), so you need a (local) webserver that sets the right HTTP headers (e.g. `qtwasmserver.py`) and cannot directly open the `.html` file locally.
You can find a Docker container that serves the prebuilt files with the right headers and also runs the required [latexonline](https://latexonline.cc/) instance [here](https://hub.docker.com/r/ncoder/ipe-web-latex-online), the Dockerfile is on [GitHub](https://github.com/N-Coder/latex-online/blob/master/Dockerfile.base).

[![A picture of people using ipe-web with a pen on an iPad](foto-gd.jpg)]([https://ipe.n-coder.de/ipe.html](https://graphdrawing.github.io/gd2024/))
> ipe-web being used on an iPad with pen input at [GD 2024](https://graphdrawing.github.io/gd2024/). Picture by [mikhubphoto](https://mikhubphoto.at/)
