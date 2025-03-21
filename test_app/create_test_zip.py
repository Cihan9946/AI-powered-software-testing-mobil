import zipfile
import os

# Zip dosyası oluştur
with zipfile.ZipFile('assets/test.zip', 'w', zipfile.ZIP_DEFLATED) as zipf:
    # test.txt dosyasını zip'e ekle
    zipf.write('assets/test.txt', 'test.txt')

print("Test zip dosyası başarıyla oluşturuldu!") 