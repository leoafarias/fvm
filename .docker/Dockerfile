FROM dart:latest

ARG FVM_VERSION

RUN apt-get update --quiet --yes
RUN apt-get install --quiet --yes \
    unzip \
    apt-utils

RUN dart pub global activate fvm ${FVM_VERSION}
