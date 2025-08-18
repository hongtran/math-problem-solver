class MathProblem {
  final String id;
  final String imageBase64;
  final String? problemDescription;
  final String? userEmail; // Changed from userId to userEmail
  final DateTime timestamp;

  MathProblem({
    required this.id,
    required this.imageBase64,
    this.problemDescription,
    this.userEmail, // Changed from userId to userEmail
    required this.timestamp,
  });

  factory MathProblem.fromJson(Map<String, dynamic> json) {
    return MathProblem(
      id: json['id'] ?? '',
      imageBase64: json['image_base64'] ?? '',
      problemDescription: json['problem_description'],
      userEmail: json['user_email'], // Changed from user_id to user_email
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_base64': imageBase64,
      'problem_description': problemDescription,
      'user_email': userEmail, // Changed from user_id to user_email
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class MathSolution {
  final String solution;
  final List<String> steps;
  final String answer;
  final double confidence;
  final double processingTime;

  MathSolution({
    required this.solution,
    required this.steps,
    required this.answer,
    required this.confidence,
    required this.processingTime,
  });

  factory MathSolution.fromJson(Map<String, dynamic> json) {
    return MathSolution(
      solution: json['solution'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      answer: json['answer'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      processingTime: (json['processing_time'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'solution': solution,
      'steps': steps,
      'answer': answer,
      'confidence': confidence,
      'processing_time': processingTime,
    };
  }
}

class MathProblemRequest {
  final String imageBase64;
  final String? userEmail; // Changed from userId to userEmail
  final String? problemDescription;

  MathProblemRequest({
    required this.imageBase64,
    this.userEmail, // Changed from userId to userEmail
    this.problemDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'image_base64': imageBase64,
      'user_email': userEmail, // Changed from user_id to user_email
      'problem_description': problemDescription,
    };
  }
} 
