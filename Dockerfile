# podman build -t ncoder/ipe-web-build:latest -f Dockerfile .
# podman run --rm --name ipe-web-build --volume $(pwd)/out:/root/out:rw,z ncoder/ipe-web-build:latest

FROM debian:latest
WORKDIR /root
COPY ./ /root
RUN /root/build.sh
