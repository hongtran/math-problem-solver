#!/bin/bash

echo "🔨 Building Flutter Frontend..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "📖 Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Navigate to frontend directory
cd src/frontend

echo "📱 Checking Flutter installation..."
flutter doctor

echo "🔧 Cleaning previous builds..."
flutter clean

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "🌐 Building Flutter web app..."
flutter build web --release

if [ $? -eq 0 ]; then
    echo "✅ Frontend built successfully!"
    echo "📁 Build output: src/frontend/build/web"
    echo "🚀 You can now run: docker-compose up --build"
else
    echo "❌ Frontend build failed!"
    exit 1
fi
