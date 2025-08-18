#!/bin/bash

echo "🔧 Math Problem Solver - Development Setup"
echo "=========================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
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
    echo "✅ .env file created. Please edit it with your OpenAI API key."
    echo "🔑 Get your API key from: https://platform.openai.com/api-keys"
    read -p "Press Enter after updating .env file..."
fi

# Check if OPENAI_API_KEY is set
if grep -q "OPENAI_API_KEY=your_openai_api_key_here" .env; then
    echo "❌ Please set your OpenAI API key in .env file before continuing."
    exit 1
fi

echo "✅ Environment configured."

# Check if frontend is built
if [ ! -d "src/frontend/build/web" ]; then
    echo ""
    echo "🔨 Frontend not built. You have two options:"
    echo ""
    echo "Option 1: Build with Flutter (Recommended)"
    echo "  1. Install Flutter: https://flutter.dev/docs/get-started/install"
    echo "  2. Run: ./build-frontend.sh"
    echo ""
    echo "Option 2: Use pre-built frontend (Quick start)"
    echo "  1. Download a pre-built version"
    echo "  2. Extract to: src/frontend/build/web"
    echo ""
    echo "Option 3: Start backend only"
    echo "  Run: docker-compose up backend"
    echo ""
    
    read -p "Which option would you like? (1/2/3): " choice
    
    case $choice in
        1)
            if command -v flutter &> /dev/null; then
                ./build-frontend.sh
            else
                echo "❌ Flutter not installed. Please install it first."
                exit 1
            fi
            ;;
        2)
            echo "📥 Please download and extract the pre-built frontend to src/frontend/build/web"
            echo "Then run: docker-compose up --build"
            exit 0
            ;;
        3)
            echo "🚀 Starting backend only..."
            docker-compose up backend
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

echo "✅ Frontend is ready."
echo "🚀 Starting all services..."
docker-compose up --build -d

echo ""
echo "🎉 Setup complete!"
echo "🌐 Frontend: http://localhost:8080"
echo "🔧 Backend: http://localhost:8000"
echo "📚 API Docs: http://localhost:8000/docs" 
