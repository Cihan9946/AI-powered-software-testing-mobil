from rest_framework import serializers
import pickle
import os
from django.conf import settings

class SecurityModelSerializer(serializers.Serializer):
    def get_model(self):
        # Model dosyasının yolu
        model_path = os.path.join(settings.BASE_DIR, 'security', 'models', 'random_forest_combined.pkl')
        
        # Modeli yükle
        with open(model_path, 'rb') as f:
            model = pickle.load(f)
        
        return model 