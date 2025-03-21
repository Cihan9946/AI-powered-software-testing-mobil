from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import subprocess
import json
import os

app = Flask(__name__)
CORS(app)  # CORS desteği ekle

# Model yükleme
model = joblib.load('random_forest_combined.pkl')

@app.route('/analyze', methods=['POST'])
def analyze_code():
    try:
        data = request.get_json()
        files = data.get('files', [])
        extract_dir = data.get('extract_dir', '')

        if not files or not extract_dir:
            return jsonify({'error': 'Dosya veya dizin bilgisi eksik'}), 400

        # Bandit analizi
        bandit_result = subprocess.run(['bandit', '-r', extract_dir, '-f', 'json'], 
                                     capture_output=True, text=True)
        bandit_output = json.loads(bandit_result.stdout) if bandit_result.stdout else {}

        # Model tahmini (örnek değerler)
        quality_score = 0.85
        security_score = 0.92

        return jsonify({
            'quality_level': 'HIGH' if quality_score > 0.8 else 'MEDIUM' if quality_score > 0.6 else 'LOW',
            'predicted_quality': quality_score,
            'security_level': 'HIGH' if security_score > 0.8 else 'MEDIUM' if security_score > 0.6 else 'LOW',
            'predicted_security': security_score,
            'ai_results': 'Detaylı analiz sonuçları buraya gelecek...',
            'bandit_results': json.dumps(bandit_output, indent=2)
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000) 