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
ARG        PREFIX=/opt/ffmpeg
ARG        MAKEFLAGS="-j2"

ENV         FFMPEG_VERSION=4.0.2     \
            FDKAAC_VERSION=0.1.5      \
            OGG_VERSION=1.3.2         \
            OPENCOREAMR_VERSION=0.1.5 \
            OPUS_VERSION=1.2          \
            OPENJPEG_VERSION=2.1.2    \
            THEORA_VERSION=1.1.1      \
            VORBIS_VERSION=1.3.5      \
            VPX_VERSION=1.7.0         \
            X264_VERSION=20170226-2245-stable \
            X265_VERSION=2.3          \
            XVID_VERSION=1.3.4        \
            FREETYPE_VERSION=2.5.5    \
            FRIBIDI_VERSION=0.19.7    \
            FONTCONFIG_VERSION=2.12.4 \
            LIBVIDSTAB_VERSION=1.1.0  \
            SRC=/usr/local

ARG         OGG_SHA256SUM="e19ee34711d7af328cb26287f4137e70630e7261b17cbe3cd41011d73a654692  libogg-1.3.2.tar.gz"
ARG         OPUS_SHA256SUM="77db45a87b51578fbc49555ef1b10926179861d854eb2613207dc79d9ec0a9a9  opus-1.2.tar.gz"
ARG         VORBIS_SHA256SUM="6efbcecdd3e5dfbf090341b485da9d176eb250d893e3eb378c428a2db38301ce  libvorbis-1.3.5.tar.gz"
ARG         THEORA_SHA256SUM="40952956c47811928d1e7922cda3bc1f427eb75680c3c37249c91e949054916b  libtheora-1.1.1.tar.gz"
ARG         FREETYPE_SHA256SUM="5d03dd76c2171a7601e9ce10551d52d4471cf92cd205948e60289251daddffa8  freetype-2.5.5.tar.gz"
ARG         LIBVIDSTAB_SHA256SUM="14d2a053e56edad4f397be0cb3ef8eb1ec3150404ce99a426c4eb641861dc0bb  v1.1.0.tar.gz"


RUN      buildDeps="autoconf \
                    automake \
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
		    nasm \
                    g++ \
                    gcc \
                    git \
                    bzip2 \
                    curl \
                    perl \
                    wget \
                    mercurial" && \
        apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ${buildDeps}
	
#add cuda 9.2 toolkit
RUN apt install -y --no-install-recommends cuda-toolkit-9-2=9.2.148-1
	
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
        curl -sL https://download.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz  | \
        tar -zx && \
        cd x265_${X265_VERSION}/build/linux && \
        sed -i "/-DEXTRA_LIB/ s/$/ -DCMAKE_INSTALL_PREFIX=\${PREFIX}/" multilib.sh && \
        sed -i "/^cmake/ s/$/ -DENABLE_CLI=OFF/" multilib.sh && \
        ./multilib.sh && \
        make -C 8bit install && \
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
        cd /tmp/ffmpeg_sources && \
        git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
        cd nv-codec-headers && \
        make && \
        make install


## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=$(mktemp -d) && cd ${DIR} && \
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        ./configure \
        --prefix="${PREFIX}"\
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
	PATH="${PREFIX}/bin:$PATH" make -j$(nproc) VERBOSE=1 && \
        make -j$(nproc) install && \
        make -j$(nproc) distclean
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
