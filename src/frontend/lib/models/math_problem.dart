class MathProblem {
  final String id;
  final String imageBase64;
  final String? problemDescription;
  final String? userEmail;
  final DateTime timestamp;

  MathProblem({
    required this.id,
    required this.imageBase64,
    this.problemDescription,
    this.userEmail,
    required this.timestamp,
  });

  factory MathProblem.fromJson(Map<String, dynamic> json) {
    return MathProblem(
      id: json['id'] ?? '',
      imageBase64: json['image_base64'] ?? '',
      problemDescription: json['problem_description'],
      userEmail: json['user_email'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_base64': imageBase64,
      'problem_description': problemDescription,
      'user_email': userEmail,
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
  final bool? verified;
  final String? correctionNote;

  MathSolution({
    required this.solution,
    required this.steps,
    required this.answer,
    required this.confidence,
    required this.processingTime,
    this.verified,
    this.correctionNote,
  });

  factory MathSolution.fromJson(Map<String, dynamic> json) {
    return MathSolution(
      solution: json['solution'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      answer: json['answer'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      processingTime: (json['processing_time'] ?? 0.0).toDouble(),
      verified: json['verified'] as bool?,
      correctionNote: json['correction_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'solution': solution,
      'steps': steps,
      'answer': answer,
      'confidence': confidence,
      'processing_time': processingTime,
      if (verified != null) 'verified': verified,
      if (correctionNote != null) 'correction_note': correctionNote,
    };
  }
}

class MathProblemRequest {
  /// Image as base64 (optional). At least one of imageBase64 or problemText/problemDescription is required.
  final String? imageBase64;
  final String? userEmail;
  /// Text description of the problem (optional). Used as fallback if problemText is null.
  final String? problemDescription;
  /// Problem statement as text (optional). Sent as problem_text to API.
  final String? problemText;

  MathProblemRequest({
    this.imageBase64,
    this.userEmail,
    this.problemDescription,
    this.problemText,
  }) : assert(
         (imageBase64 != null && imageBase64.isNotEmpty) ||
             (problemText != null && problemText.isNotEmpty) ||
             (problemDescription != null && problemDescription.isNotEmpty),
         'At least one of imageBase64, problemText, or problemDescription is required',
       );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_email': userEmail,
    };
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      map['image_base64'] = imageBase64;
    }
    if (problemText != null && problemText!.isNotEmpty) {
      map['problem_text'] = problemText;
    }
    if (problemDescription != null && problemDescription!.isNotEmpty) {
      map['problem_description'] = problemDescription;
    }
    return map;
  }
}

class MathProblemHistory {
  final String id;
  final String imageBase64;
  final String? problemDescription;
  final String? userEmail;
  final DateTime timestamp;
  final List<String> steps;
  final String answer;

  MathProblemHistory({
    required this.id,
    required this.imageBase64,
    this.problemDescription,
    required this.userEmail,
    required this.timestamp,
    required this.steps,
    required this.answer,
  });
  
  factory MathProblemHistory.fromJson(Map<String, dynamic> json) {
    return MathProblemHistory(
      id: json['id'] ?? '',
      imageBase64: json['image_base64'] ?? '',
      problemDescription: json['problem_description'],
      userEmail: json['user_email'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      steps: List<String>.from(json['steps'] ?? []),
      answer: json['answer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_base64': imageBase64,
      'problem_description': problemDescription,
      'user_email': userEmail,
      'timestamp': timestamp.toIso8601String(),
      'steps': steps,
      'answer': answer,
    };
  }
}
