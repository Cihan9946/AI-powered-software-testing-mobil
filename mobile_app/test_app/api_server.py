from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import subprocess
import json
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from io import BytesIO
import base64
import logging
import tempfile
import shutil

# Logging ayarları
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

try:
    # Model yükleme
    model = joblib.load('random_forest_combined.pkl')
    logger.info("Model başarıyla yüklendi")
    logger.info(f"Model tipi: {type(model)}")
except Exception as e:
    logger.error(f"Model yüklenirken hata oluştu: {str(e)}")
    raise

def generate_visualizations(bandit_results):
    try:
        if not bandit_results or 'results' not in bandit_results:
            return None

        plt.figure(figsize=(10, 6))
        severity_counts = pd.DataFrame(bandit_results['results']).groupby('issue_severity').size()
        severity_counts.plot(kind='bar', color=['red', 'orange', 'yellow'])
        plt.title('Güvenlik Sorunlarının Önem Seviyesi Dağılımı')
        plt.xlabel('Önem Seviyesi')
        plt.ylabel('Sayı')
        
        img_buffer = BytesIO()
        plt.savefig(img_buffer, format='png')
        img_buffer.seek(0)
        img_str = base64.b64encode(img_buffer.getvalue()).decode()
        plt.close()
        
        return img_str
    except Exception as e:
        logger.error(f"Görselleştirme oluşturulurken hata: {str(e)}")
        return None

def calculate_scores(bandit_output, total_files, python_files):
    """Bandit sonuçlarına göre kalite ve güvenlik skorlarını hesapla"""
    try:
        # Bandit metriklerini al
        metrics = bandit_output.get('metrics', {}).get('_totals', {})
        
        # Güvenlik skoru hesaplama
        high_severity = metrics.get('SEVERITY.HIGH', 0)
        medium_severity = metrics.get('SEVERITY.MEDIUM', 0)
        low_severity = metrics.get('SEVERITY.LOW', 0)
        
        # Kalite skoru hesaplama
        total_loc = max(metrics.get('loc', 1), 1)  # 0'a bölünmeyi önlemek için minimum 1
        nosec = metrics.get('nosec', 0)
        
        # Güvenlik skoru (0-1 arası)
        security_score = 1.0 - min(1.0, (high_severity * 0.7 + medium_severity * 0.3 + low_severity * 0.1) / total_loc)
        
        # Kalite skoru (0-1 arası)
        quality_score = 1.0 - min(1.0, nosec / total_loc)
        
        return quality_score, security_score
    except Exception as e:
        logger.error(f"Skor hesaplama hatası: {str(e)}")
        return 0.5, 0.5  # Varsayılan değerler

def process_android_files(files, extract_dir):
    """Android dosya yollarını işle ve geçici dizine kopyala"""
    try:
        # Geçici dizin oluştur
        temp_dir = tempfile.mkdtemp()
        logger.debug(f"Geçici dizin oluşturuldu: {temp_dir}")
        
        # Dosyaları kopyala
        for file_path in files:
            if os.path.exists(file_path):
                file_name = os.path.basename(file_path)
                dest_path = os.path.join(temp_dir, file_name)
                shutil.copy2(file_path, dest_path)
                logger.debug(f"Dosya kopyalandı: {file_path} -> {dest_path}")
            else:
                logger.warning(f"Dosya bulunamadı: {file_path}")
        
        return temp_dir
    except Exception as e:
        logger.error(f"Dosya işleme hatası: {str(e)}")
        raise

@app.route('/analyze', methods=['POST'])
def analyze_code():
    try:
        data = request.get_json()
        logger.debug(f"Gelen veri: {data}")
        
        files = data.get('files', [])
        extract_dir = data.get('extract_dir', '')

        if not files or not extract_dir:
            logger.error("Dosya veya dizin bilgisi eksik")
            return jsonify({'error': 'Dosya veya dizin bilgisi eksik'}), 400

        # Android dosyalarını işle
        try:
            temp_dir = process_android_files(files, extract_dir)
            logger.debug(f"İşlenen dosyalar: {os.listdir(temp_dir)}")
        except Exception as e:
            logger.error(f"Dosya işleme hatası: {str(e)}")
            return jsonify({'error': f'Dosya işleme hatası: {str(e)}'}), 500

        # Bandit analizi
        try:
            bandit_result = subprocess.run(['bandit', '-r', temp_dir, '-f', 'json'], 
                                         capture_output=True, text=True)
            logger.debug(f"Bandit çıktısı: {bandit_result.stdout}")
            bandit_output = json.loads(bandit_result.stdout) if bandit_result.stdout else {}
        except Exception as e:
            logger.error(f"Bandit analizi sırasında hata: {str(e)}")
            return jsonify({'error': f'Bandit analizi başarısız: {str(e)}'}), 500
        finally:
            # Geçici dizini temizle
            try:
                shutil.rmtree(temp_dir)
                logger.debug("Geçici dizin temizlendi")
            except Exception as e:
                logger.warning(f"Geçici dizin temizlenirken hata: {str(e)}")

        # Skorları hesapla
        total_files = len(files)
        python_files = sum(1 for f in files if f.endswith('.py'))
        quality_score, security_score = calculate_scores(bandit_output, total_files, python_files)

        # Görselleştirme oluştur
        visualization = generate_visualizations(bandit_output)

        # Detaylı rapor
        metrics = bandit_output.get('metrics', {}).get('_totals', {})
        detailed_report = {
            'total_files': total_files,
            'python_files': python_files,
            'total_issues': len(bandit_output.get('results', [])),
            'high_severity_issues': metrics.get('SEVERITY.HIGH', 0),
            'medium_severity_issues': metrics.get('SEVERITY.MEDIUM', 0),
            'low_severity_issues': metrics.get('SEVERITY.LOW', 0),
            'issue_distribution': {
                'HIGH': metrics.get('SEVERITY.HIGH', 0),
                'MEDIUM': metrics.get('SEVERITY.MEDIUM', 0),
                'LOW': metrics.get('SEVERITY.LOW', 0)
            },
            'top_issues': bandit_output.get('results', [])[:5]
        }

        response = {
            'quality_level': 'HIGH' if quality_score > 0.8 else 'MEDIUM' if quality_score > 0.6 else 'LOW',
            'predicted_quality': float(quality_score),
            'security_level': 'HIGH' if security_score > 0.8 else 'MEDIUM' if security_score > 0.6 else 'LOW',
            'predicted_security': float(security_score),
            'detailed_report': detailed_report,
            'visualization': visualization,
            'bandit_results': bandit_output
        }

        logger.debug(f"Yanıt: {response}")
        return jsonify(response)

    except Exception as e:
        logger.error(f"Genel hata: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000) 