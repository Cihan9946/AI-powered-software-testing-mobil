import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickAndExtractZip,
          child: const Text('Zip Dosyası Yükle ve Çıkar'),
        ),
      ),
    );
  }
}