# Math Problem Solver

An AI-powered application that helps students solve mathematics homework problems using computer vision and large language models.

## 🚀 Features

- **Image Capture**: Take photos or upload images of math problems
- **AI-Powered Solutions**: Get step-by-step solutions using OpenAI's GPT-4 Vision
- **Problem History**: Track all solved problems with timestamps
- **Modern UI**: Beautiful Flutter interface with Material Design 3
- **Cross-Platform**: Works on web, mobile, and desktop
- **Real-time Processing**: Fast API responses with progress indicators

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter      │    │   FastAPI       │    │   OpenAI        │
│   Frontend     │◄──►│   Backend       │◄──►│   GPT-4 Vision  │
│                │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   Firebase      │    │   Image Storage │
│   (Optional)    │    │   & Processing  │
└─────────────────┘    └─────────────────┘
```

## 🛠️ Tech Stack

### Backend
- **FastAPI**: Modern Python web framework
- **OpenAI API**: GPT-4 Vision for math problem solving
- **Pillow**: Image processing and manipulation
- **Firebase Admin**: User management and data storage (optional)

### Frontend
- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **Image Picker**: Camera and gallery integration
- **HTTP**: API communication

### Infrastructure
- **Docker**: Containerization
- **Docker Compose**: Multi-service orchestration

## 📋 Prerequisites

- Python 3.8+
- Flutter SDK 3.0+
- Docker and Docker Compose
- OpenAI API key
- Firebase project and service account key (optional, for user management and history)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd math-problem-solver
```

### 2. Set Up Environment Variables

Create a `.env` file in the root directory:

```bash
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
```

### 3. Set Up Firebase Service Account Key (Optional)

If you want to use Firebase for user authentication and problem history storage, you need to set up a Firebase service account key:

1. **Create a Firebase Project**:
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select an existing one

2. **Generate Service Account Key**:
   - In your Firebase project, go to **Project Settings** > **Service Accounts**
   - Click **Generate new private key**
   - Download the JSON file

3. **Configure credentials (env-based — no key file in repo)**  
   Use one of these options (copy `src/backend/env.example` to `.env` in backend or project root first):
   - **Option 1:** Set individual env vars from the key JSON: `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY_ID`, `FIREBASE_PRIVATE_KEY` (use `\n` for newlines in the key), `FIREBASE_CLIENT_EMAIL`, `FIREBASE_CLIENT_ID`.

   **Optional local fallback:** You can still place a file named `serviceAccountKey.json` in `src/backend/` for local dev; it is ignored by git. Env vars take precedence.

4. **Enable Firestore**:
   - In Firebase Console, go to **Firestore Database**
   - Click **Create database**
   - Choose production mode or test mode based on your needs

**Note**: The application will work without Firebase, but user authentication and problem history features will be disabled.

### 4. Run with Docker (Recommended)

```bash
# Start all services
docker-compose up --build

# Access the application
# Frontend: http://localhost:8080
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

### 5. Manual Setup (Alternative)

#### Backend Setup

```bash
cd src/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### Frontend Setup

```bash
cd src/frontend

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run -d chrome  # For web
flutter run             # For connected device
```

## 📱 Usage

### 1. Capture Math Problem
- Use the camera to take a photo of your math problem
- Or select an existing image from your gallery
- Optionally add a description for better context

### 2. Solve Problem
- Tap "Solve Problem" to send the image to AI
- Wait for the AI to analyze and solve the problem
- View the step-by-step solution and final answer

### 3. Review History
- Check the History tab to see all solved problems
- Reuse previous problems or share solutions
- Track your learning progress

## 🔧 Configuration

### API Endpoints

- `GET /`: API information
- `GET /health`: Health check
- `POST /solve-math-problem`: Solve math problem from image
- `POST /upload-image`: Upload and process image
- `GET /user-problems/{user_id}`: Get user's problem history

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key for GPT-4 Vision | Required |
| `HOST` | Backend server host | `0.0.0.0` |
| `PORT` | Backend server port | `8000` |
| `DEBUG` | Enable debug mode | `True` |

## 🧪 Testing

### Backend Tests

```bash
cd src/backend
python -m pytest tests/
```

### Frontend Tests

```bash
cd src/frontend
flutter test
```

## 📦 Deployment

### Production Build

```bash
# Backend
cd src/backend
docker build -t math-solver-backend .

# Frontend
cd src/frontend
flutter build web
```

### Docker Production

```bash
# Build and run production containers
docker-compose -f docker-compose.prod.yml up -d
```

## 🔒 Security Considerations

- **API Key Protection**: Never expose OpenAI API keys in client code
- **Input Validation**: All user inputs are validated and sanitized
- **Rate Limiting**: Implement rate limiting for production use
- **CORS Configuration**: Restrict CORS origins in production
- **Image Processing**: Validate image types and sizes

## 🚧 Limitations

- **Image Quality**: High-quality, clear images work best
- **Complex Problems**: Very complex mathematical expressions may have reduced accuracy
- **API Costs**: OpenAI API usage incurs costs based on image size and complexity
- **Processing Time**: Solution generation depends on OpenAI API response time

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenAI for providing the GPT-4 Vision API
- Flutter team for the amazing cross-platform framework
- FastAPI for the modern Python web framework
- The open-source community for various dependencies

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/your-repo/issues) page
2. Create a new issue with detailed information
3. Contact the development team

## 🔄 Updates

Stay updated with the latest features and improvements:

```bash
git pull origin main
docker-compose down
docker-compose up --build
```

---

**Happy Math Solving! 🧮✨** 
