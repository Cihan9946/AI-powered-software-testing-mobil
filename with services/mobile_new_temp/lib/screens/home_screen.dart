import 'package:flutter/material.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/report_screen.dart';
import 'package:archive/archive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String? _selectedFilePath;
  bool _isLoading = false;

  Future<void> _selectFile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Geçici dizin oluştur
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/sonhali22,04,2025.zip';
      
      // ZIP dosyasını geçici dizine kopyala
      final ByteData data = await rootBundle.load('assets/sonhali22,04,2025.zip');
      final File destFile = File(tempPath);
      await destFile.writeAsBytes(data.buffer.asUint8List());

      if (await destFile.exists()) {
        setState(() {
          _selectedFilePath = tempPath;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ZIP dosyası başarıyla seçildi')),
        );
      } else {
        throw Exception('Dosya oluşturulamadı: $tempPath');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçilirken hata oluştu: $e')),
      );
    }
  }

  Future<String> _extractZip(String zipPath) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // ZIP dosyasını oku
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Çıkartma dizini oluştur
      final Directory tempDir = await getTemporaryDirectory();
      final String extractPath = '${tempDir.path}/extracted_${DateTime.now().millisecondsSinceEpoch}';
      final Directory extractDir = Directory(extractPath);
      await extractDir.create(recursive: true);

      // Dosyaları çıkart
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final File outFile = File('$extractPath/$filename');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory('$extractPath/$filename').create(recursive: true);
        }
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ZIP dosyası başarıyla çıkartıldı')),
      );

      return extractPath;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('ZIP dosyası çıkartılırken hata oluştu: $e');
    }
  }

  Future<void> _analyzeFile() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir ZIP dosyası seçin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('ZIP dosyası çıkartılıyor...');
      // ZIP dosyasını çıkart
      final extractedPath = await _extractZip(_selectedFilePath!);
      print('ZIP dosyası çıkartıldı: $extractedPath');
      
      // API'den model bilgilerini al
      final model = await _apiService.getSecurityModel();
      
      if (model != null) {
        // Rapor sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(
              extractedPath: extractedPath,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model yüklenemedi')),
        );
      }
    } catch (e) {
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Analizi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _selectFile,
              child: const Text('ZIP Dosyası Seç'),
            ),
            const SizedBox(height: 20),
            if (_selectedFilePath != null)
              Text('Seçilen dosya: $_selectedFilePath'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeFile,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Analiz Et'),
            ),
          ],
        ),
      ),
    );
  }
} 