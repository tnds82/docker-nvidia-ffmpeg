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
