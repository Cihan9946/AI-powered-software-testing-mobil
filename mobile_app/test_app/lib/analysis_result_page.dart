import 'package:flutter/material.dart';

class AnalysisResultPage extends StatelessWidget {
  final String fileName;
  final String qualityLevel;
  final double predictedQuality;
  final String securityLevel;
  final double predictedSecurity;
  final Map<String, dynamic> detailedReport;
  final Map<String, dynamic> banditResults;
  final String? visualization;

  const AnalysisResultPage({
    super.key,
    required this.fileName,
    required this.qualityLevel,
    required this.predictedQuality,
    required this.securityLevel,
    required this.predictedSecurity,
    required this.detailedReport,
    required this.banditResults,
    this.visualization,
  });

  Color _getQualityColor(String level) {
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

  Widget _buildMetricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Analiz Raporu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dosya Bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dosya: $fileName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analiz Tarihi: ${DateTime.now().toString().split('.')[0]}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Yazılım Kalitesi Analizi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yazılım Kalitesi Analizi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getQualityColor(qualityLevel).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalite Seviyesi: $qualityLevel',
                            style: TextStyle(
                              color: _getQualityColor(qualityLevel),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kalite Skoru: ${predictedQuality.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getQualityColor(securityLevel).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Güvenlik Seviyesi: $securityLevel',
                            style: TextStyle(
                              color: _getQualityColor(securityLevel),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Güvenlik Skoru: ${predictedSecurity.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detaylı Rapor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detaylı Rapor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          'Toplam Dosya',
                          detailedReport['total_files'].toString(),
                        ),
                        _buildMetricCard(
                          'Python Dosyası',
                          detailedReport['python_files'].toString(),
                        ),
                        _buildMetricCard(
                          'Toplam Sorun',
                          detailedReport['total_issues'].toString(),
                        ),
                        _buildMetricCard(
                          'Yüksek Önemli Sorun',
                          detailedReport['high_severity_issues'].toString(),
                        ),
                        _buildMetricCard(
                          'Orta Önemli Sorun',
                          detailedReport['medium_severity_issues'].toString(),
                        ),
                        _buildMetricCard(
                          'Düşük Önemli Sorun',
                          detailedReport['low_severity_issues'].toString(),
                        ),
                      ],
                    ),
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