import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/security_model.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  final String extractedPath;

  const ReportScreen({
    Key? key,
    required this.extractedPath,
  }) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  SecurityModel? _model;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _analyzeProject();
  }

  Future<void> _analyzeProject() async {
    try {
      print('Analiz başlatılıyor...');
      print('Dosya yolu: ${widget.extractedPath}');
      
      final model = await _apiService.analyzeFile(widget.extractedPath);
      print('Analiz tamamlandı: ${model.status}');
      
      setState(() {
        _model = model;
        _isLoading = false;
      });
    } catch (e) {
      print('Analiz hatası: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getLevel(double score) {
    if (score > 0.7) return 'High';
    if (score > 0.4) return 'Medium';
    return 'Low';
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hata'),
        ),
        body: Center(
          child: Text(_errorMessage),
        ),
      );
    }

    if (_model == null) {
      return const Scaffold(
        body: Center(
          child: Text('Model yüklenemedi'),
        ),
      );
    }

    final qualityLevel = _getLevel(_model!.predictedQuality);
    final securityLevel = _getLevel(_model!.predictedSecurity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Raporu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yazılım Kalite Analizi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yazılım Kalite Analizi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kalite Seviyesi: $qualityLevel',
                      style: TextStyle(
                        color: _getLevelColor(qualityLevel),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _model!.predictedQuality,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getLevelColor(qualityLevel),
                      ),
                    ),
                    Text('Skor: ${(_model!.predictedQuality * 100).toStringAsFixed(2)}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Güvenlik Analizi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Güvenlik Analizi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Güvenlik Seviyesi: $securityLevel',
                      style: TextStyle(
                        color: _getLevelColor(securityLevel),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _model!.predictedSecurity,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getLevelColor(securityLevel),
                      ),
                    ),
                    Text('Skor: ${(_model!.predictedSecurity * 100).toStringAsFixed(2)}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Detaylı Bulgular
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detaylı Güvenlik Bulguları',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._model!.securityIssues.map((issue) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(issue),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI Önerileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Model Önerileri',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._model!.aiRecommendations.map((recommendation) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(recommendation),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 