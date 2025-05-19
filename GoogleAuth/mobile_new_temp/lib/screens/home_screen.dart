import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'report_screen.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const HomeScreen({
    Key? key,
    required this.authService,
    required this.apiService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedFilePath;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Analizi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı Bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Kullanıcı',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Dosya Seçme ve Analiz Bölümü
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
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _selectFile,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('ZIP Dosyası Seç'),
                    ),
                    if (_selectedFilePath != null) ...[
                      const SizedBox(height: 8),
                      Text('Seçilen dosya: $_selectedFilePath'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _analyzeFile,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.security),
                        label: Text(_isLoading ? 'Analiz Ediliyor...' : 'Analiz Et'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Önceki Analizler
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Önceki Analizler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('uploads')
                          .where('user', isEqualTo: user?.email)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Hata: ${snapshot.error}');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('Henüz analiz edilmiş dosya yok.');
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            
                            return ListTile(
                              title: Text(data['zip_name'] ?? 'İsimsiz Dosya'),
                              subtitle: Text(
                                'Yüklenme: ${(data['upload_time'] as Timestamp).toDate().toString()}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteFile(doc.id),
                              ),
                              onTap: () => _viewReport(doc.id),
                            );
                          },
                        );
                      },
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

  Future<void> _deleteFile(String docId) async {
    try {
      await _firestore.collection('uploads').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya başarıyla silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya silinirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _viewReport(String docId) async {
    try {
      final doc = await _firestore.collection('uploads').doc(docId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportScreen(
                extractedPath: data['extracted_path'] ?? '',
                banditResults: data['bandit_results'] ?? {},
                aiResults: data['ai_results'] ?? {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor görüntülenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _selectFile() async {
    // Burada dosya seçme işlemi yapılacak
    // Şimdilik sabit bir dosya yolu kullanıyoruz
    setState(() {
      _selectedFilePath = 'assets/sonhali22-04-2025.zip';
    });
  }

  Future<void> _analyzeFile() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Analiz başlatılıyor...');
      print('Dosya yolu: $_selectedFilePath');
      
      // ZIP dosyasını assets'ten oku
      final byteData = await rootBundle.load(_selectedFilePath!);
      final bytes = byteData.buffer.asUint8List();
      
      // Geçici bir dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_zip.zip');
      await tempFile.writeAsBytes(bytes);
      
      // ZIP dosyasını analiz et
      final extractedPath = '${tempDir.path}/extracted';
      final extractDir = Directory(extractedPath);
      
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create();
      
      // ZIP dosyasını çıkart
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final outFile = File('${extractDir.path}/${file.name}');
        
        // Dizin yapısını oluştur
        if (file.name.contains('/')) {
          final dirPath = outFile.parent.path;
          final dir = Directory(dirPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        }
        
        if (file.isFile) {
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }
      
      print('Dosyalar başarıyla çıkartıldı: $extractedPath');

      // Firestore'a kaydet
      final user = widget.authService.currentUser;
      if (user != null) {
        await _firestore.collection('uploads').add({
          'user': user.email,
          'zip_name': _selectedFilePath!.split('/').last,
          'upload_time': FieldValue.serverTimestamp(),
          'extracted_path': extractedPath,
          'bandit_results': {'test': 'sample bandit result'},
          'ai_results': {'test': 'sample AI result'},
        });
      }
      
      // Rapor sayfasına yönlendir
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(
              extractedPath: extractedPath,
            ),
          ),
        );
      }
    } catch (e) {
      print('Analiz hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz sırasında hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 