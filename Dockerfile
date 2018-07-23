# ffmpeg - http://ffmpeg.org/download.html
#
# From https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
#
# https://hub.docker.com/r/jrottenberg/ffmpeg/
#
#
FROM nvidia/cuda:9.2-base-ubuntu16.04 AS base

WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 libexpat1-dev && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM base as build

ARG        PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
ARG        LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG        PREFIX=/opt/ffmpeg/
ARG        MAKEFLAGS="-j2"

ENV         FFMPEG_VERSION=4.0.2     \
            FDKAAC_VERSION=0.1.5      \
	    OPENCOREAMR_VERSION=0.1.5 \
            X264_VERSION=20170226-2245-stable \
            X265_VERSION=2.3          \
            SRC=/usr/local

RUN      buildDeps="autoconf \
                    automake \
                    cmake \
                    curl \
                    bzip2 \
                    libexpat1-dev \
                    g++ \
                    gcc \
                    git \
                    gperf \
                    libtool \
                    make \
                    nasm \
                    perl \
                    pkg-config \
                    python \
                    libssl-dev \
                    yasm \
                    libva-dev \
                    zlib1g-dev \
                    expat \
                    libgomp1 \
                    build-essential \
                    libass-dev \
                    libtool \
                    texinfo \
                    zlib1g-dev \
                    curl \
                    wget \
                    mercurial" && \
        apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ${buildDeps}
	
#add cuda 9.2 toolkit
RUN apt install -y --no-install-recommends cuda-toolkit-9-2=9.2.148-1

## opencore-amr https://sourceforge.net/projects/opencore-amr/
RUN \
        DIR=/tmp/opencore-amr && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://kent.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCOREAMR_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-shared  && \
        make && \
        make install && \
        rm -rf ${DIR}

## x264 http://www.videolan.org/developers/x264.html
RUN \
        DIR=/tmp/x264 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
        tar -jx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-shared --enable-pic --disable-cli && \
        make && \
        make install && \
        rm -rf ${DIR}
	
### x265 http://x265.org/
RUN \
        DIR=/tmp/x265 && \
	mkdir -p ${DIR} && \
        cd ${DIR} && \
	hg clone https://bitbucket.org/multicoreware/x265 && \
	cd x265 && \
	cmake -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} source && \
	make && \
	make install && \
	rm -rf ${DIR}

### fdk-aac https://github.com/mstorsjo/fdk-aac
RUN \
        DIR=/tmp/fdk-aac && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --enable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}
	
RUN \
        DIR=/tmp/nv-codec-headers && \
        git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
        cd ${DIR} && \
        make && \
        make install && \
	rm -rf ${DIR}


## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        ./configure \
        --prefix="${PREFIX}" \
        --pkg-config-flags="--static" \
        --extra-cflags="-I${PREFIX}/include" \
        --extra-ldflags="-L${PREFIX}/lib" \
        --bindir="${PREFIX}/bin" \
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
        make && \
	make install && \
	make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${PREFIX}/bin
## cleanup
RUN \
        ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
        cp ${PREFIX}/bin/* /usr/local/bin/ && \
        cp -r ${PREFIX}/share/ffmpeg /usr/local/share/ && \
        LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf

FROM        base AS release
MAINTAINER  Julien Rottenberg <julien@rottenberg.info>

CMD         ["--help"]
ENTRYPOINT  ["ffmpeg"]
ENV         LD_LIBRARY_PATH=/usr/local/lib

COPY --from=build /usr/local /usr/local/

RUN \
	apt-get update -y && \
	apt-get install -y --no-install-recommends libva-drm1 libva1 && \
	rm -rf /var/lib/apt/lists/*

# Let's make sure the app built correctly
# Convenient to verify on https://hub.docker.com/r/jrottenberg/ffmpeg/builds/ console output
