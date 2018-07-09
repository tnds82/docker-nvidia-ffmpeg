FROM nvidia/cuda

WORKDIR /tmp

RUN apt-get -yqq update && \
    apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 && \
    apt-get autoremove -y && \
    apt-get clean -y
    
RUN     buildDeps="autoconf \
                   automake \
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
                   mercurial" && \
    apt-get -yqq upate && \
    apt-get install -yq --no-install-recommends ${buildDeps}
