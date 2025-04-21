import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  // Zip dosyası analiz sonuçlarını tutacak değişken
  Map<String, dynamic> _zipAnalysisResult = {};
  bool _isAnalyzing = false;

  void _pickAndExtractZip() async {
    // Kullanıcıdan zip dosyası seçmesini isteyin
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null) {
      // Seçilen dosyanın yolu
      String filePath = result.files.single.path!;
      // Zip dosyasını çıkar
      _extractZip(filePath);
    }
  }

  void _extractZip(String filePath) async {
    // Zip dosyasını oku
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Çıkarılacak dizin
    final outputDir = Directory(path.dirname(filePath));
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    // Dosyaları çıkar
    for (final file in archive) {
      final filename = path.join(outputDir.path, file.name);
      if (file.isFile) {
        final outFile = File(filename);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        Directory(filename).create(recursive: true);
      }
    }

    // Başarılı bir şekilde çıkarıldığında kullanıcıya bilgi ver
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zip dosyası başarıyla çıkarıldı!')),
    );
  }

  // Assets klasöründeki test2.zip dosyasını analiz et
  void _analyzeAssetsZip() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Assets klasöründeki test2.zip dosyasını oku
      final ByteData data = await rootBundle.load('assets/test2.zip');
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // Zip dosyasını analiz et
      _analyzeZip(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  // Zip dosyasını analiz et ve rapor oluştur
  void _analyzeZip(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Analiz sonuçlarını tutacak değişkenler
      int totalFiles = 0;
      int totalFolders = 0;
      int totalSize = 0;
      List<String> fileNames = [];
      List<String> folderNames = [];
      Map<String, int> fileSizes = {};
      
      // Zip içeriğini analiz et
      for (final file in archive) {
        if (file.isFile) {
          totalFiles++;
          fileNames.add(file.name);
          fileSizes[file.name] = file.content.length;
          totalSize += file.content.length;
        } else {
          totalFolders++;
          folderNames.add(file.name);
        }
      }
      
      // Analiz sonuçlarını kaydet
      setState(() {
        _zipAnalysisResult = {
          'totalFiles': totalFiles,
          'totalFolders': totalFolders,
          'totalSize': totalSize,
          'fileNames': fileNames,
          'folderNames': folderNames,
          'fileSizes': fileSizes,
        };
      });
      
      // Analiz sonuçlarını göster
      _showAnalysisReport();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zip analiz hatası: $e')),
      );
    }
  }

  // Analiz raporunu göster
  void _showAnalysisReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Zip Dosyası Analiz Raporu'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Toplam Dosya Sayısı: ${_zipAnalysisResult['totalFiles']}'),
              Text('Toplam Klasör Sayısı: ${_zipAnalysisResult['totalFolders']}'),
              Text('Toplam Boyut: ${(_zipAnalysisResult['totalSize'] / 1024).toStringAsFixed(2)} KB'),
              SizedBox(height: 10),
              Text('Dosyalar:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._zipAnalysisResult['fileNames'].map<Widget>((fileName) {
                int fileSize = _zipAnalysisResult['fileSizes'][fileName];
                return Text('$fileName (${(fileSize / 1024).toStringAsFixed(2)} KB)');
              }).toList(),
              if (_zipAnalysisResult['folderNames'].isNotEmpty) ...[
                SizedBox(height: 10),
                Text('Klasörler:', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._zipAnalysisResult['folderNames'].map<Widget>((folderName) {
                  return Text(folderName);
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
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
            ElevatedButton(
              onPressed: _pickAndExtractZip,
              child: const Text('Zip Dosyası Yükle ve Çıkar'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeAssetsZip,
              child: _isAnalyzing 
                ? CircularProgressIndicator() 
                : const Text('Assets Zip Dosyasını Analiz Et'),
            ),
          ],
        ),
      ),
    );
  }
}