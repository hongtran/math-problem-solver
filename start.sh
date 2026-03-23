#!/bin/bash

echo "🚀 Starting Math Problem Solver Application..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cat > .env << EOF
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=True

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
EOF
    echo "📝 Please edit .env file with your OpenAI API key and other configurations."
    echo "🔑 Get your OpenAI API key from: https://platform.openai.com/api-keys"
    read -p "Press Enter after updating .env file..."
fi

# Check if OPENAI_API_KEY is set
if grep -q "OPENAI_API_KEY=your_openai_api_key_here" .env; then
    echo "❌ Please set your OpenAI API key in .env file before continuing."
    exit 1
fi

# Check if Flutter frontend is built
if [ ! -d "src/frontend/build/web" ]; then
    echo "🔨 Frontend not built. Building Flutter web app..."
    if command -v flutter &> /dev/null; then
        ./build-frontend.sh
        if [ $? -ne 0 ]; then
            echo "❌ Frontend build failed. Please check Flutter installation."
            exit 1
        fi
    else
        echo "❌ Flutter not installed. Please install Flutter first."
        echo "📖 Install from: https://flutter.dev/docs/get-started/install"
        echo "🔨 Or manually build the frontend and place it in src/frontend/build/web"
        exit 1
    fi
fi

echo "✅ Frontend is built and ready."
echo "🔧 Building and starting services..."
docker-compose up --build -d

echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend API is running at http://localhost:8000"
    echo "📚 API Documentation: http://localhost:8000/docs"
else
    echo "❌ Backend API failed to start. Check logs with: docker-compose logs backend!"
fi

if curl -f http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Frontend is running at http://localhost:8080"
else
    echo "❌ Frontend failed to start. Check logs with: docker-compose logs frontend"
fi

echo ""
echo "🎉 Math Problem Solver is starting up!"
echo "🌐 Open http://localhost:8080 in your browser"
echo ""
echo "📋 Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart: docker-compose restart"
echo "  Rebuild: docker-compose up --build"
echo "  Rebuild frontend: ./build-frontend.sh"
echo ""
echo "🔍 Troubleshooting:"
echo "  If you encounter issues, check the logs above"
echo "  Ensure your OpenAI API key is valid and has credits"
echo "  Check that ports 8000 and 8080 are available"
echo "  For frontend changes, rebuild with: ./build-frontend.sh" 
