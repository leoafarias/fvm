FROM dart:latest

# Set fvm version
ARG FVM_VERSION

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Update and install dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip

# Run install.sh with an argument
RUN curl -fsSL https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/install.sh | bash -s "$FVM_VERSION"