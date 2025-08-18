import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:math_problem_solver/models/math_problem.dart';
import 'package:math_problem_solver/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _currentUserEmail; // Add email field
  bool _isLoadingHistory = false; // Flag to prevent multiple history loads

  // Getters
  MathSolverState get state => _state;
  MathSolution? get currentSolution => _currentSolution;
  List<MathProblem> get problemHistory => _problemHistory;
  String? get errorMessage => _errorMessage;
  Uint8List? get selectedImage => _selectedImage;
  String? get selectedImageName => _selectedImageName;
  bool get isApiConnected => _isApiConnected;
  String? get currentUserEmail => _currentUserEmail; // Getter for email
  bool get isLoadingHistory => _isLoadingHistory; // Getter for history loading state

  /// Set current user email
  Future<void> setUserEmail(String email) async {
    _currentUserEmail = email;
    
    // Save to shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
    } catch (e) {
      // Handle error silently
      debugPrint('Failed to save email: $e');
    }
    
    notifyListeners();
  }

  /// Clear current user email
  Future<void> clearUserEmail() async {
    _currentUserEmail = null;
    _problemHistory.clear();
    _isLoadingHistory = false;
    
    // Clear from shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
    } catch (e) {
      // Handle error silently
      debugPrint('Failed to clear email: $e');
    }
    
    notifyListeners();
  }

  /// Check if user email is set
  bool get hasUserEmail => _currentUserEmail != null && _currentUserEmail!.isNotEmpty;

  /// Get filtered problem history for current user
  List<MathProblem> get userProblemHistory {
    if (_currentUserEmail == null) return [];
    return _problemHistory.where((problem) => problem.userEmail == _currentUserEmail).toList();
  }

  /// Load user email from shared preferences
  Future<void> loadUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _currentUserEmail = savedEmail;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Failed to load email: $e');
    }
  }

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
  Future<void> solveMathProblem({String? problemDescription}) async {
    if (_selectedImage == null) {
      _setError('No image selected');
      return;
    }

    if (!hasUserEmail) {
      _setError('Please enter your email first');
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
        userEmail: _currentUserEmail,
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
      userEmail: request.userEmail,
      timestamp: DateTime.now(),
    );

    _problemHistory.insert(0, problem);
    
    // Keep only last 50 problems
    if (_problemHistory.length > 50) {
      _problemHistory = _problemHistory.take(50).toList();
    }
  }

  /// Load user problem history
  Future<void> loadUserProblems(String userEmail) async {
    // Prevent multiple simultaneous calls
    if (_isLoadingHistory) {
      print('History loading already in progress, skipping...');
      return;
    }
    
    try {
      _isLoadingHistory = true;
      _setLoading();
      
      print('Loading user problems for email: $userEmail');
      final problems = await ApiService.getUserProblems(userEmail);
      
      _problemHistory = problems;
      _state = MathSolverState.success;
      _errorMessage = null;
      
      print('Successfully loaded ${problems.length} problems');
      notifyListeners();
    } catch (e) {
      print('Error loading user problems: $e');
      _setError('Failed to load problem history: ${e.toString()}');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
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
    _currentUserEmail = null;
    _isLoadingHistory = false;
    notifyListeners();
  }
} 
