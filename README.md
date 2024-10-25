# ipe-web

> [!IMPORTANT]
> By now, ipe has [built-in support](https://github.com/otfried/ipe/tree/master/src/ipejs) for a JavaScript UI.
> This repository, that still uses the more cumbersome Qt for WebAssembly UI, is mostly kept for archival purposes.

This repository contains a script to build an HTML5 webassembly version of the [ipe editor](https://ipe.otfried.org/) via [emscripten](https://emscripten.org/).
You can try the resulting web app at [ipe.n-coder.de](https://ipe.n-coder.de/ipe.html).
While most of ipe already works, some parts (uploading/downloading files, ipelets, changing preferences...) are still work in progress.
Furthermore, the software should be considered alpha-level, so there may be still be broken functionalities or even crashes.

[![A screenshot of ipe in a browser](screenshot.png)](https://ipe.n-coder.de/ipe.html)

## Building / Running

There are three main steps to developing / deploying ipe-web yourself:
(1) Building all of ipe's dependencies via emscripten, (2) building ipe itself, and (3) setting up a server that serves ipe-web the right way and provides the required [latexonline](https://latexonline.cc/) API.
Points one and two are handled by the scripts `./install.sh` and `./build-ipe.sh`, respectively, while the modified version of latexonline for point 3 can be found [here](https://github.com/N-Coder/latex-online).
For more details on the individual steps see below.

### Building dependencies
The build scripts are targeted at a current Debian (while the resulting webassembly is of course system independent); it is recommended to run them inside a Debian docker container or VM.
There is a ready-made docker container [`ncoder/ipe-web-build`](https://hub.docker.com/layers/ncoder/ipe-web-build/latest/) that already contains all dependencies prebuilt.
Note that the built dependencies (and thereby also this container image) take up roughly 30 GB.
Skip ahead to the next section if you want to use the prebuilt container instead of building it / all dependencies on your own.

The `./install.sh` script contains the necessary commands for installing all necessary tools and building all dependencies with emscripten.
The `ncoder/ipe-web-build` container was built by splitting the `./install.sh` script into multiple container build stages and combining it with the commands from `Dockerfile.in` to obtain a normal `Dockerfile` by using the `./make-dockerfile.py` script.
Note that building all dependencies via `./install.sh` or the resulting `Dockerfile` will take quite some time (about 2h on my laptop) and will generate roughly 30GB of data, mostly due to the two required [Qt 6 builds](https://doc.qt.io/qt-6/wasm.html).
You can abort the build (both via `./install.sh` and via docker) at any point and restart while re-using most of the previous results.

So if you want to build this container on your own, run the following:
```bash
python3 ./make-dockerfile.py # combines Dockerfile.in and install.sh into Dockerfile
docker build -t ncoder/ipe-web-build:latest -f Dockerfile .
```
If `docker` is not easily available on your system, you might want to try [`podman`](https://podman.io/) as a more modern drop-in replacement.


### Building ipe
Once all dependencies are available, `./build_ipe.sh` clones the source code of ipe to `download/ipe`, builds the webassembly site, and stores the build results in the `out` folder.
You can also make changes to the cloned ipe code and simply re-run `./build_ipe.sh`.
A precompiled version of the results can be found in the [releases section](https://github.com/N-Coder/ipe-web/releases) of this repo.

If you are using the prebuilt dependencies docker container, use the following to build ipe-web in the container:
```bash
docker run -ti --name ipe-web-build --volume $(pwd)/out:/root/out:rw,z ncoder/ipe-web-build:latest
./build_ipe.sh # run within the container to build ipe
```
The `--volume $(pwd)/out:/root/out` flag will ensure that the build results are copied to the `out` folder in your current working directory.
Instead of interactively making changes to the ipe clone within the container, you can use the following to directly build an already checked-out version of ipe from your host machine (assumed to lie at the path `$IPE_PATH`) with any modifications it contains:
```bash
docker run --rm --name ipe-web-build --volume $(pwd)/out:/root/out:rw,z --volume $IPE_PATH/out:/root/download/ipe:rw,z ncoder/ipe-web-build:latest ./build_ipe.sh
```

### Running the server
You can find a Docker container that serves the built files the right way (for details see below) and also runs the required [latexonline](https://latexonline.cc/) instance [here](https://hub.docker.com/r/ncoder/ipe-web-latex-online/tags), the Dockerfile is on [GitHub](https://github.com/N-Coder/latex-online/blob/master/Dockerfile.base).
So, once your build is complete, simply run the following to get a daemon that serves ipe-web at port 2700:
```bash
docker run -d -p 2700:2700 --rm --name latex-online --volume $(pwd)/out:/var/www/public:ro,z ncoder/ipe-web-latex-online:latest
```
If you want to access this server from anywhere else than `localhost`, you need to use a HTTPS connection, e.g. by using Let's Encrypt together with an Apache httpd reverse proxy as described [here](https://santoshgawande.com/secure-reverse-proxy-using-apache-with-lets-encrypt-d49d9abd2481)

The background to all this is that, while most modern browsers support ipe-web perfectly well, they also have [special requirements](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer#security_requirements) to the way how the site is served:
- the site needs to be accessed via a [secure context](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts), that is, either be accessed via `localhost` or by using HTTPS
- the site needs to be served with the appropriate [cross-origin isolation headers](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer#security_requirements)

This especially means the the site can neither be accessed directly from the file system via `file://` urls nor served by any plain-old development web server that does not set these headers.
For more backgrounds, see also the notes on running Qt6 WebAssembly code [here](https://doc.qt.io/qt-6/wasm.html#running-applications) and the blue box at the top of [this site](https://emscripten.org/docs/porting/pthreads.html).

Additionally, to compile the LaTeX code contained in ipe documents, ipe-web needs access to a server providing the [latexonline](https://latexonline.cc/) API.
By default, this server is assumed to run at the same address serving ipe-web.
This [repo](https://github.com/N-Coder/latex-online/) contains a slightly modified version of latexonline that sets the correct headers for additionally serving the static ipe-web files, so you can use the modified latexonline to provide the API *and* serve ipe-web with the correct headers.

[![A picture of people using ipe-web with a pen on an iPad](foto-gd.jpg)]([https://ipe.n-coder.de/ipe.html](https://graphdrawing.github.io/gd2024/))
> ipe-web being used on an iPad with pen input at [GD 2024](https://graphdrawing.github.io/gd2024/). Picture by [mikhubphoto](https://mikhubphoto.at/)
