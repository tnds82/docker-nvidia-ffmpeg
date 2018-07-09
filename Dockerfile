FROM nvidia/cuda

WORKDIR /tmp

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
                   mercurial" && \
       apt-get -yqq update && \
       apt-get install -yq --no-install-recommends ${buildDeps}
