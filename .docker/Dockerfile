FROM google/dart:latest

ENV FVM_VERSION "1.3.7"

RUN apt-get update --quiet --yes
RUN apt-get install --quiet --yes \
    unzip \
    apt-utils

RUN pub global activate fvm ${FVM_VERSION}
