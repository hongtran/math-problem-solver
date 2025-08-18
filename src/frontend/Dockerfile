FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set up environment variables
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH

# Download and install Flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
RUN flutter channel stable
RUN flutter upgrade
RUN flutter doctor

# Set up working directory
WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml ./

# Get Flutter dependencies (this will create pubspec.lock if it doesn't exist)
RUN flutter pub get

# Copy source code
COPY . .

# Ensure all dependencies are resolved
RUN flutter pub get

# Build the app for web
RUN flutter build web --web-renderer html

# Install a simple HTTP server
RUN apt-get update && apt-get install -y python3-pip
RUN pip3 install http-server

# Expose port
EXPOSE 8080

# Start the HTTP server
CMD ["python3", "-m", "http.server", "8080", "--directory", "build/web"] 
