# 📱 AI Tabanlı Mobil Yazılım Testi Uygulaması

Bu proje, Flutter ile geliştirilen bir mobil uygulamadır. Kullanıcılar, yazılım projelerini `.zip` dosyası olarak yükleyerek bu projelerin **güvenlik** ve **kalite** açısından değerlendirilmesini sağlar. Uygulama, arka planda çalışan bir **yapay zeka modeli** ile projeyi analiz eder ve sonuçları kullanıcıya yüzde olarak sunar.

---

## 🚀 Özellikler

- 📦 ZIP formatında yazılım projesi yükleme
- 🧠 Yapay zeka ile analiz (güvenlik ve kalite skoru)
- ☁️ Backend'e dosya gönderimi (API üzerinden)
- 📊 Kullanıcıya görselleştirilmiş analiz sonucu sunumu

---

## 🛠️ Kullanılan Teknolojiler

### Mobil Uygulama (Frontend):
- Flutter
- Dart
- File Picker
- HTTP (API bağlantısı)
- Provider veya Bloc (state management)

### Sunucu Tarafı (Backend):
- Python (FastAPI / Flask)
- Bandit (Security analyzer)
- Statik analiz araçları
- Önceden eğitilmiş ML modeli (`random_forest_combined.pkl`)

---

## 🧪 Yapay Zeka Analizi

Yüklenen yazılım projesi şu adımlarla analiz edilir:

1. **ZIP Açma**: ZIP dosyası sunucuda açılır.
2. **Kod Analizi**: Python kodları taranır.
3. **Güvenlik Tarayıcı (Bandit)**: Güvenlik açıkları analiz edilir.
4. **Kalite Analizi**: Kodun okunabilirliği, tekrar eden kodlar, yorumlar vs.
5. **Model Tahmini**: Güvenlik ve kalite skorları `Random Forest` modeli ile tahmin edilir.
6. **Sonuç Gönderimi**: Yüzdelik olarak güvenlik ve kalite skorları mobil uygulamaya JSON formatında döner.

---

## 📲 Uygulama Ekranları (Örnekler)

- ZIP seçme ekranı
- Analiz süreci animasyonu
- Sonuç ekranı (% güvenlik ve % kalite)

---

## 🔐 Güvenlik ve Gizlilik

Yüklenen projeler sadece analiz amaçlıdır ve hiçbir yerde saklanmaz. İşlem tamamlandığında otomatik olarak sunucudan silinir.

---

## 📌 Kurulum ve Çalıştırma

### Flutter Uygulaması:
```bash
git clone https://github.com/kullaniciAdi/mobil-test-ai.git
cd mobil-test-ai
flutter pub get
flutter run
