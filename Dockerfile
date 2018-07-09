FROM nvidia/cuda

WORKDIR /tmp

#build depends
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
                   curl \
                   perl \
                   wget \
                   mercurial" && \
       apt-get -yqq update && \
       apt-get install -yq --no-install-recommends ${buildDeps}

#build nasm
RUN mkdir ffmpeg_sources && cd ffmpeg_sources && \
    wget http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/nasm-2.14rc0.tar.gz && \
    tar xzvf nasm-2.14rc0.tar.gz && \
    cd nasm-2.14rc0 && \
    ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
    make -j$(nproc) VERBOSE=1 && \
    make -j$(nproc) install && \
    make -j$(nproc) distclean

#build x264
RUN cd /tmp/ffmpeg_sources && \
    git clone http://git.videolan.org/git/x264.git -b stable && \
    cd x264/ && \
    PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-opencl && \
    PATH="$HOME/bin:$PATH" make -j$(nproc) VERBOSE=1 && \
    make -j$(nproc) install && \
    make -j$(nproc) distclean
    
#build x265
RUN cd /tmp/ffmpeg_sources && \
    hg clone https://bitbucket.org/multicoreware/x265 && \
    cd /tmp/ffmpeg_sources/x265/build/linux && \
    PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source && \
    make -j$(nproc) VERBOSE=1 && \
    make -j$(nproc) install && \
    make -j$(nproc) clean
    
#build fdk-aac
RUN cd /tmp/ffmpeg_sources && \
    wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master && \
    tar xzvf fdk-aac.tar.gz && \
    cd mstorsjo-fdk-aac* && \
    autoreconf -fiv && \
    ./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
    make -j$(nproc) VERBOSE=1 && \
    make -j$(nproc) install && \
    make -j$(nproc) distclean && \
    
#build nv-codec
RUN cd /tmp/ffmpeg_sources && \
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && \
    make && \
    make install
    
#build ffmpeg
RUN cd /tmp/ffmpeg_sources && \
    git clone https://github.com/FFmpeg/FFmpeg -b master && \
    cd FFmpeg && \
    PATH="$HOME/bin:$PATH" \
        PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
        ./configure \
        --prefix="$HOME/ffmpeg_build" \
        --pkg-config-flags="--static" \
        --extra-cflags="-I$HOME/ffmpeg_build/include" \
        --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
        --bindir="$HOME/bin" \
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
    PATH="$HOME/bin:$PATH" make -j$(nproc) VERBOSE=1 && \
    make -j$(nproc) install && \
    make -j$(nproc) distclean

