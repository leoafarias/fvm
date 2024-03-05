# syntax=docker/dockerfile:1

# Use an official Linux runtime as a parent image
FROM ubuntu:latest

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Update and install dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip

# Run install.sh
RUN curl -fsSL https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/install.sh | bash
