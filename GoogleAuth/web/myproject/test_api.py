import requests

def test_security_model_api():
    # API endpoint URL'si
    url = 'http://localhost:8000/security/api/model/'
    
    try:
        # GET isteği gönder
        response = requests.get(url)
        
        # Yanıtı kontrol et
        if response.status_code == 200:
            print("API Başarılı!")
            print("Yanıt:", response.json())
        else:
            print(f"Hata! Status Code: {response.status_code}")
            print("Hata Mesajı:", response.text)
            
    except Exception as e:
        print(f"Bir hata oluştu: {str(e)}")

if __name__ == "__main__":
    test_security_model_api() 