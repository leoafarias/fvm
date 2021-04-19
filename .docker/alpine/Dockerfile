FROM alpine:3.13

USER root

ARG FVM_VERSION
ARG GLIBC_VERSION="2.28-r0"

# Install Required Tools
RUN apk -U update && apk -U add \
  bash \
  ca-certificates \
  curl \
  git \
  make \
  libstdc++ \
  libgcc \
  mesa-dev \
  unzip \
  wget \
  zlib \
  && wget https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -O /etc/apk/keys/sgerrand.rsa.pub \
	&& wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk -O /tmp/glibc.apk \
	&& wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk -O /tmp/glibc-bin.apk \
	&& apk add /tmp/glibc.apk /tmp/glibc-bin.apk \
  && rm -rf /tmp/* \
	&& rm -rf /var/cache/apk/* \
  && addgroup -g 1000 flutter \
  && adduser -u 1000 -G flutter -s /bin/bash -D flutter

USER flutter

ARG HOME=/home/flutter

ENV PATH=$HOME/fvm:$HOME/.pub-cache/bin:$HOME/fvm/default/bin:${PATH}

RUN cd $HOME \
  && wget https://github.com/leoafarias/fvm/releases/download/${FVM_VERSION}/fvm-${FVM_VERSION}-linux-x64.tar.gz \
  && tar -xf fvm-${FVM_VERSION}-linux-x64.tar.gz \
  && rm fvm-${FVM_VERSION}-linux-x64.tar.gz \
  && fvm --version