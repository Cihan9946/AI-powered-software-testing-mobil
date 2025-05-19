class SecurityModel {
  final String status;
  final String message;
  final String modelInfo;
  final double predictedQuality;
  final double predictedSecurity;
  final List<String> securityIssues;
  final List<String> aiRecommendations;
  final String primaryLanguage;
  final Map<String, dynamic> languageStats;
  final int totalSyntaxErrors;
  final Map<String, dynamic> syntaxErrorsByLanguage;

  SecurityModel({
    required this.status,
    required this.message,
    required this.modelInfo,
    required this.predictedQuality,
    required this.predictedSecurity,
    required this.securityIssues,
    required this.aiRecommendations,
    required this.primaryLanguage,
    required this.languageStats,
    required this.totalSyntaxErrors,
    required this.syntaxErrorsByLanguage,
  });

  factory SecurityModel.fromJson(Map<String, dynamic> json) {
    return SecurityModel(
      status: json['status'],
      message: json['message'],
      modelInfo: json['model_info'],
      predictedQuality: json['predicted_quality']?.toDouble() ?? 0.0,
      predictedSecurity: json['predicted_security']?.toDouble() ?? 0.0,
      securityIssues: List<String>.from(json['security_issues'] ?? []),
      aiRecommendations: List<String>.from(json['ai_recommendations'] ?? []),
      primaryLanguage: json['primary_language'] ?? 'Unknown',
      languageStats: json['language_stats'] ?? {},
      totalSyntaxErrors: json['total_syntax_errors'] ?? 0,
      syntaxErrorsByLanguage: json['syntax_errors_by_language'] ?? {},
    );
  }
} 