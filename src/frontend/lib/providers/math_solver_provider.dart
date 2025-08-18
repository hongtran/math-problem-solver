import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:math_problem_solver/models/math_problem.dart';
import 'package:math_problem_solver/services/api_service.dart';

enum MathSolverState {
  idle,
  loading,
  success,
  error,
}

class MathSolverProvider extends ChangeNotifier {
  MathSolverState _state = MathSolverState.idle;
  MathSolution? _currentSolution;
  List<MathProblem> _problemHistory = [];
  String? _errorMessage;
  Uint8List? _selectedImage;
  String? _selectedImageName;
  bool _isApiConnected = false;

  // Getters
  MathSolverState get state => _state;
  MathSolution? get currentSolution => _currentSolution;
  List<MathProblem> get problemHistory => _problemHistory;
  String? get errorMessage => _errorMessage;
  Uint8List? get selectedImage => _selectedImage;
  String? get selectedImageName => _selectedImageName;
  bool get isApiConnected => _isApiConnected;

  /// Check API connection status
  Future<void> checkApiConnection() async {
    try {
      _isApiConnected = await ApiService.checkApiHealth();
      notifyListeners();
    } catch (e) {
      _isApiConnected = false;
      notifyListeners();
    }
  }

  /// Set selected image
  void setSelectedImage(Uint8List imageBytes, String fileName) {
    _selectedImage = imageBytes;
    _selectedImageName = fileName;
    _errorMessage = null;
    _currentSolution = null;
    _state = MathSolverState.idle;
    notifyListeners();
  }

  /// Clear selected image
  void clearSelectedImage() {
    _selectedImage = null;
    _selectedImageName = null;
    _currentSolution = null;
    _errorMessage = null;
    _state = MathSolverState.idle;
    notifyListeners();
  }

  /// Solve math problem
  Future<void> solveMathProblem({String? problemDescription, String? userId}) async {
    if (_selectedImage == null) {
      _setError('No image selected');
      return;
    }

    try {
      _setLoading();

      // Convert image to base64
      final imageBase64 = await ApiService.uploadImage(_selectedImage!, _selectedImageName ?? 'math_problem.jpg');

      // Create request
      final request = MathProblemRequest(
        imageBase64: imageBase64,
        problemDescription: problemDescription,
        userId: userId,
      );

      // Solve problem
      final solution = await ApiService.solveMathProblem(request);

      // Update state
      _currentSolution = solution;
      _state = MathSolverState.success;
      _errorMessage = null;

      // Add to history
      _addToHistory(request, solution);

      notifyListeners();
    } catch (e) {
      _setError('Failed to solve math problem: ${e.toString()}');
    }
  }

  /// Add solved problem to history
  void _addToHistory(MathProblemRequest request, MathSolution solution) {
    final problem = MathProblem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageBase64: request.imageBase64,
      problemDescription: request.problemDescription,
      userId: request.userId,
      timestamp: DateTime.now(),
    );

    _problemHistory.insert(0, problem);
    
    // Keep only last 50 problems
    if (_problemHistory.length > 50) {
      _problemHistory = _problemHistory.take(50).toList();
    }
  }

  /// Load user problem history
  Future<void> loadUserProblems(String userId) async {
    try {
      _setLoading();
      final problems = await ApiService.getUserProblems(userId);
      _problemHistory = problems;
      _state = MathSolverState.success;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load problem history: ${e.toString()}');
    }
  }

  /// Clear current solution
  void clearSolution() {
    _currentSolution = null;
    _errorMessage = null;
    _state = MathSolverState.idle;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    if (_state == MathSolverState.error) {
      _state = MathSolverState.idle;
    }
    notifyListeners();
  }

  /// Set loading state
  void _setLoading() {
    _state = MathSolverState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set error state
  void _setError(String message) {
    _state = MathSolverState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _state = MathSolverState.idle;
    _currentSolution = null;
    _errorMessage = null;
    _selectedImage = null;
    _selectedImageName = null;
    notifyListeners();
  }
} 
