import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:math_problem_solver/models/math_problem.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Dynamic base URL based on platform and environment
  static String get baseUrl {
    // You can override this with an environment variable for different setups
    const String customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    
    // Use kIsWeb to detect web platform
    if (kIsWeb) {
      // For web, use localhost
      return 'http://localhost:8000';
    } else {
      // For mobile platforms, detect platform
      if (Platform.isIOS) {
        // iOS simulator uses localhost to access host machine
        return 'http://localhost:8000';
      } else if (Platform.isAndroid) {
        // Android emulator uses 10.0.2.2 to access host machine
        return 'http://10.0.2.2:8000';
      } else {
        // For other platforms (desktop), use localhost
        return 'http://localhost:8000';
      }
    }
  }
  
  // Alternative method for manual IP configuration (useful for physical devices)
  static String getBaseUrlForPhysicalDevice(String hostIpAddress) {
    return 'http://$hostIpAddress:8000';
  }

  // Get current platform info for debugging
  static String getPlatformInfo() {
    if (kIsWeb) {
      return 'Web Platform - using localhost';
    } else {
      if (Platform.isIOS) {
        return 'iOS Platform - using localhost';
      } else if (Platform.isAndroid) {
        return 'Android Platform - using 10.0.2.2';
      } else {
        return '${Platform.operatingSystem} Platform - using localhost';
      }
    }
  }

  // Method to test connectivity to the API
  static Future<bool> testConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Connectivity test failed: $e');
      print('Platform info: ${getPlatformInfo()}');
      print('Using base URL: $baseUrl');
      return false;
    }
  }
  
  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Solve a math problem by sending image to the API
  static Future<MathSolution> solveMathProblem(MathProblemRequest request) async {
    try {
      print('Attempting to solve math problem...');
      print('Platform info: ${getPlatformInfo()}');
      print('Using base URL: $baseUrl');
      
      final response = await http.post(
        Uri.parse('$baseUrl/solve-math-problem'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return MathSolution.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to solve math problem');
      }
    } catch (e) {
      print('Error solving math problem: $e');
      print('Platform info: ${getPlatformInfo()}');
      print('Base URL: $baseUrl');
      
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Cannot connect to server at $baseUrl. ${getPlatformInfo()}. Error: $e');
      } else {
        throw Exception('Network error: $e');
      }
    }
  }

  /// Upload an image and get base64 representation
  static Future<String> uploadImage(Uint8List imageBytes, String filename) async {
    try {
      // Convert image to base64
      final base64String = base64Encode(imageBytes);
      return base64String;
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  /// Alternative method to upload image directly to server
  static Future<Map<String, dynamic>> uploadImageToServer(Uint8List imageBytes, String filename) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-image'),
      );

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['detail'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Get user's solved problems history
  static Future<List<MathProblem>> getUserProblems(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-problems/$userEmail'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> problemsList = data['problems'] ?? [];
        return problemsList.map((json) => MathProblem.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch user problems');
      }
    } catch (e) {
      throw Exception('Failed to fetch user problems: $e');
    }
  }

  /// Check API health
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get API root information
  static Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get API info');
      }
    } catch (e) {
      throw Exception('Failed to get API info: $e');
    }
  }
} 
