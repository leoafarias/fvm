FROM dart:stable

# Set fvm version
ARG FVM_VERSION

# Canonical install script used by tooling validation
ENV FVM_INSTALL_SCRIPT_URL=https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/install.sh

# Set the working directory in the container to /app
WORKDIR /app

# Copy pubspec files first for better layer caching
COPY pubspec.* ./

# Get dependencies first
RUN dart pub get --no-precompile

# Copy the rest of the application
COPY . .

# Update and install system dependencies, then clean up
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip \
    && rm -rf /var/lib/apt/lists/*

# Build FVM from source instead of installing from remote
RUN dart compile exe bin/main.dart -o /usr/local/bin/fvm

# Verify installation
RUN fvm --version
