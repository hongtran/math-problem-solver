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
  List<MathProblemHistory> _problemHistory = [];
  String? _errorMessage;
  Uint8List? _selectedImage;
  String? _selectedImageName;
  bool _isApiConnected = false;
  String? _currentUserEmail;
  bool _isLoadingHistory = false;
  String? _historyLoadError;

  // Getters
  MathSolverState get state => _state;
  MathSolution? get currentSolution => _currentSolution;
  List<MathProblemHistory> get problemHistory => _problemHistory;
  String? get errorMessage => _errorMessage;
  String? get historyLoadError => _historyLoadError;
  Uint8List? get selectedImage => _selectedImage;
  String? get selectedImageName => _selectedImageName;
  bool get isApiConnected => _isApiConnected;
  String? get currentUserEmail => _currentUserEmail;
  bool get isLoadingHistory => _isLoadingHistory;

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
    _historyLoadError = null;
    
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
  List<MathProblemHistory> get userProblemHistory {
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

  /// Solve math problem from image and/or text. Provide at least one: selected image or problemDescription/problemText.
  Future<void> solveMathProblem({String? problemDescription, String? problemText}) async {
    final hasImage = _selectedImage != null;
    final hasText = (problemText ?? problemDescription ?? '').trim().isNotEmpty;
    if (!hasImage && !hasText) {
      _setError('Select an image or enter a problem (text)');
      return;
    }

    if (!hasUserEmail) {
      _setError('Please enter your email first');
      return;
    }

    try {
      _setLoading();

      String? imageBase64;
      if (hasImage) {
        imageBase64 = await ApiService.uploadImage(_selectedImage!, _selectedImageName ?? 'math_problem.jpg');
      }

      final request = MathProblemRequest(
        imageBase64: imageBase64,
        problemDescription: problemDescription,
        problemText: problemText ?? problemDescription,
        userEmail: _currentUserEmail,
      );

      // Solve problem
      final solution = await ApiService.solveMathProblem(request);

      // Update state
      _currentSolution = solution;
      _state = MathSolverState.success;
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      _setError('Failed to solve math problem: ${e.toString()}');
    }
  }

  /// Load user problem history (does not touch [state] / solve-tab loading UI).
  Future<void> loadUserProblems(String userEmail) async {
    if (_isLoadingHistory) {
      debugPrint('History loading already in progress, skipping...');
      return;
    }

    try {
      _isLoadingHistory = true;
      _historyLoadError = null;
      notifyListeners();

      debugPrint('Loading user problems for email: $userEmail');
      final problems = await ApiService.getUserProblems(userEmail);

      _problemHistory = problems;
      debugPrint('Successfully loaded ${problems.length} problems');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user problems: $e');
      _historyLoadError = 'Failed to load problem history: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void clearHistoryLoadError() {
    _historyLoadError = null;
    notifyListeners();
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
    _historyLoadError = null;
    notifyListeners();
  }
} 
