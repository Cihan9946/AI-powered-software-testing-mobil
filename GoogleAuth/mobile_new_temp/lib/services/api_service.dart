import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/security_model.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'YOUR_API_BASE_URL'; // API'nizin base URL'sini buraya ekleyin
  final SharedPreferences _prefs;

  ApiService(this._prefs);

  // Android emülatör için localhost:8000 yerine 10.0.2.2:8000 kullanıyoruz
  static const String baseUrlStatic = 'http://10.0.2.2:8000';

  Future<SecurityModel> getSecurityModel() async {
    try {
      print('API isteği gönderiliyor: $baseUrlStatic/security/api/model/');
      final response = await http.get(
        Uri.parse('$baseUrlStatic/security/api/model/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('API yanıtı: ${response.statusCode}');
      print('API yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SecurityModel.fromJson(data);
      } else {
        throw Exception('API isteği başarısız: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('API hatası: $e');
      throw Exception('API isteği sırasında hata oluştu: $e');
    }
  }

  Future<void> _addFileToArchive(Archive archive, String filePath, String basePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final relativePath = path.relative(filePath, from: basePath);
    archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
  }

  Future<void> _addDirectoryToArchive(Archive archive, String dirPath, String basePath) async {
    final dir = Directory(dirPath);
    final files = await dir.list(recursive: true).toList();
    
    for (final file in files) {
      if (file is File) {
        await _addFileToArchive(archive, file.path, basePath);
      }
    }
  }

  Future<SecurityModel> analyzeFile(String extractedPath) async {
    try {
      print('Analiz başlatılıyor...');
      print('Dosya yolu: $extractedPath');

      // Dosyaları zip olarak hazırla
      final tempDir = await getTemporaryDirectory();
      final zipPath = path.join(tempDir.path, 'analysis_files.zip');
      
      // Archive oluştur
      final archive = Archive();
      await _addDirectoryToArchive(archive, extractedPath, extractedPath);
      
      // Zip dosyasını kaydet
      final encoder = ZipEncoder();
      final zipData = encoder.encode(archive);
      if (zipData == null) {
        throw Exception('Zip dosyası oluşturulamadı');
      }
      
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipData);
      print('Dosya sıkıştırıldı: $zipPath');

      // Zip dosyasını yükle
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrlStatic/security/api/analyze/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          zipPath,
        ),
      );

      print('API isteği gönderiliyor...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Analiz yanıtı: ${response.statusCode}');
      print('Analiz yanıt içeriği: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SecurityModel.fromJson(data);
      } else {
        throw Exception('Analiz isteği başarısız: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Analiz hatası: $e');
      throw Exception('Analiz sırasında hata oluştu: $e');
    }
  }

  // Kullanıcı verilerini senkronize et
  Future<void> syncUserData() async {
    try {
      final userEmail = _prefs.getString('user_email');
      if (userEmail == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/$userEmail'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_prefs.getString('auth_token')}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Kullanıcı verilerini güncelle
        await _prefs.setString('user_data', json.encode(data));
      }
    } catch (e) {
      print('Veri senkronizasyon hatası: $e');
    }
  }

  // Kullanıcı verilerini güncelle
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final userEmail = _prefs.getString('user_email');
      if (userEmail == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/api/user/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_prefs.getString('auth_token')}',
        },
        body: json.encode({
          'email': userEmail,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        // Başarılı güncelleme
        await syncUserData(); // Verileri yeniden senkronize et
      }
    } catch (e) {
      print('Veri güncelleme hatası: $e');
    }
  }

  // Kullanıcı verilerini al
  Map<String, dynamic>? getUserData() {
    final userData = _prefs.getString('user_data');
    if (userData == null) return null;
    return json.decode(userData);
  }
} 