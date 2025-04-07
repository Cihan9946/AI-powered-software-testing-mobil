import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'analysis_result_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Güvenlik Analiz Uygulaması',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Güvenlik Analiz Uygulaması'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;

  Future<void> _pickAndExtractZip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
        withData: true,
        withReadStream: true,
      );

      if (result != null) {
        if (result.files.single.path != null) {
          String filePath = result.files.single.path!;
          await _extractAndAnalyzeZip(filePath);
        } else if (result.files.single.bytes != null) {
          // Dosya yolu yoksa, geçici bir dosya oluştur
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp.zip');
          await tempFile.writeAsBytes(result.files.single.bytes!);
          await _extractAndAnalyzeZip(tempFile.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya seçilemedi. Lütfen tekrar deneyin.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir ZIP dosyası seçin')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçiminde hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _useTestZip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Test ZIP dosyasını assets'ten yükle
      final ByteData data = await rootBundle.load('assets/test.zip');
      final List<int> bytes = data.buffer.asUint8List();
      
      // Geçici bir dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/test.zip');
      await tempFile.writeAsBytes(bytes);
      
      // ZIP dosyasını çıkar ve analiz et
      await _extractAndAnalyzeZip(tempFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test ZIP dosyası işlenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _extractAndAnalyzeZip(String filePath) async {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/extracted');
      if (!extractDir.existsSync()) {
        extractDir.createSync(recursive: true);
      }

      List<String> extractedFiles = [];

      for (final file in archive) {
        final filename = path.join(extractDir.path, file.name);
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
          extractedFiles.add(filename);
        } else {
          Directory(filename).create(recursive: true);
        }
      }

      if (extractedFiles.isNotEmpty) {
        // API'ye dosyaları gönder ve analiz sonuçlarını al
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'files': extractedFiles,
            'extract_dir': extractDir.path,
          }),
        );

        if (response.statusCode == 200) {
          final analysisResult = jsonDecode(response.body);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalysisResultPage(
                  fileName: path.basename(filePath),
                  qualityLevel: analysisResult['quality_level'],
                  predictedQuality: analysisResult['predicted_quality'],
                  securityLevel: analysisResult['security_level'],
                  predictedSecurity: analysisResult['predicted_security'],
                  aiResults: analysisResult['ai_results'],
                  banditResults: analysisResult['bandit_results'],
                ),
              ),
            );
          }
        } else {
          throw Exception('API yanıt hatası: ${response.statusCode}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analiz hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'ZIP Dosyası Seçin',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickAndExtractZip,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('ZIP Dosyası Seç ve Analiz Et'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _useTestZip,
                      icon: const Icon(Icons.file_copy),
                      label: const Text('Test ZIP\'i Analiz Et'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        backgroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Lütfen analiz etmek istediğiniz ZIP dosyasını seçin veya test ZIP\'i kullanın',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}