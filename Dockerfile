FROM nvidia/video-codec-sdk:8.2-ubuntu18.04

MAINTAINER Tnds <tndsrepo@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NOWARNINGS yes

RUN     buildDeps="autoconf \
                   automake \
                   ca-certificates \
                   expat \
                   libgomp1 \
                   cmake \
                   build-essential \
                   libass-dev \
                   libtool \
                   pkg-config \
                   texinfo \
                   zlib1g-dev \
                   make \
                   g++ \
                   gcc \
                   git \
                   bzip2 \
                   mingw-w64 \
                   curl \
                   perl \
                   wget \
                   mercurial" && \
       apt-get -yqq update && \
       apt-get install -yq --no-install-recommends ${buildDeps}

## cuda
RUN \
        DIR=/tmp/cuda && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        wget https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers/cuda_9.2.148_396.37_linux && \
        bash ./cuda_9.2.148_396.37_linux --silent --toolkit --toolkitpath=/usr/local && \
        rm -rf ${DIR}

## nasm
RUN \
        echo "Build nasm" && \
        DIR=/tmp/nasm && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        wget http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/nasm-2.14rc0.tar.gz && \
        tar xzvf nasm-2.14rc0.tar.gz && \
        cd nasm-2.14rc0 && \
        ./configure --prefix="/usr/local" --bindir="/usr/local/bin" && \
        make -j$(nproc) VERBOSE=1 && \
        make -j$(nproc) install && \
        make -j$(nproc) distclean && \
        rm -rf ${DIR}

## x264
RUN \
        echo "Build x264" && \
        DIR=/tmp/x264 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        git clone http://git.videolan.org/git/x264.git -b stable && \
        cd x264/ && \
        PATH="/usr/local/bin:$PATH" \
                                ./configure \
                                --prefix="/usr/local" \
                                --bindir="/usr/local/bin" \
                                --enable-static \
                                --enable-pic \
                                --disable-opencl && \
        PATH="/usr/local/bin:$PATH" make -j$(nproc) VERBOSE=1 && \
        make -j$(nproc) install && \
        make -j$(nproc) distclean && \
        rm -rf ${DIR}

## x265
RUN \
        echo "Build x265" && \
        DIR=/tmp/x265 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        hg clone https://bitbucket.org/multicoreware/x265 && \
        cd ${DIR}/x265/build/linux && \
        PATH="/usr/local/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/usr/local" -DENABLE_SHARED:bool=off ../../source && \
        make -j$(nproc) VERBOSE=1 && \
        make -j$(nproc) install && \
        make -j$(nproc) clean && \
        rm -rf ${DIR}

## fdk-aac
RUN \
        echo "Build fdk-aac" && \
        DIR=/tmp/fdk-aac && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master && \
        tar xzvf fdk-aac.tar.gz && \
        cd mstorsjo-fdk-aac* && \
        autoreconf -fiv && \
        ./configure --prefix="/usr/local" --disable-shared && \
        make -j$(nproc) VERBOSE=1 && \
        make -j$(nproc) install && \
        make -j$(nproc) distclean && \
        rm -rf ${DIR}

## nv-codec
RUN \
        echo "Build nv-codec" && \
        DIR=/tmp/nv-codec && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
        cd nv-codec-headers && \
        make && \
        make install && \
        rm -rf ${DIR}

## ffmpeg
RUN \
        echo "Build ffmpeg" && \
        DIR=/tmp/ffmpeg && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        git clone https://github.com/FFmpeg/FFmpeg -b master && \
        cd FFmpeg && \
        PATH="$HOME/bin:$PATH" \
                PKG_CONFIG_PATH="/usr/local/lib/pkgconfig" \
                ./configure \
                --prefix="/usr/local" \
                --pkg-config-flags="--static" \
                --extra-cflags="-I/usr/local/include" \
                --extra-ldflags="-L/usr/local/lib" \
                --bindir="/usr/local/bin" \
                --enable-cuda-sdk \
                --enable-cuvid \
                --enable-libnpp \
                --extra-cflags="-I/usr/local/cuda/include/" \
                --extra-ldflags=-L/usr/local/cuda/lib64/ \
                --nvccflags="-gencode arch=compute_61,code=sm_61 -O2" \
                --enable-gpl \
                --enable-libass \
                --enable-libfdk-aac \
                --enable-libx264 \
                --extra-libs=-lpthread \
                --enable-libx265 \
                --enable-nvenc \
                --enable-nonfree && \
        PATH="/usr/local/bin:$PATH" make -j$(nproc) VERBOSE=1 && \
        make -j$(nproc) install && \
        make -j$(nproc) distclean && \
        rm -rf ${DIR}

ENV PATH /usr/local/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/lib:${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH /usr/local/lib64:${LD_LIBRARY_PATH}
