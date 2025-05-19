// Firebase yapılandırması
const firebaseConfig = {
    apiKey: "AIzaSyA-SM1ZQHEKtCgNoWMEG6WXhctpznpCZkU",
    authDomain: "newmobile-c1fb3.firebaseapp.com",
    projectId: "newmobile-c1fb3",
    storageBucket: "newmobile-c1fb3.firebasestorage.app",
    messagingSenderId: "514875911347",
    appId: "1:514875911347:web:d7baf13bc54f6e7cc314c6",
    measurementId: "G-ELV69L505X"
  };

// Firebase'i başlat
firebase.initializeApp(firebaseConfig);

// Google Sign-In işleyicisi
document.getElementById('google-signin').addEventListener('click', async () => {
    try {
        const provider = new firebase.auth.GoogleAuthProvider();
        await firebase.auth().signInWithPopup(provider);
    } catch (error) {
        console.error('Google Sign-In hatası:', error);
        showMessage('Giriş yapılırken hata oluştu: ' + error.message, 'error');
    }
});

// Çıkış yapma işleyicisi
document.getElementById('logout-btn').addEventListener('click', async () => {
    try {
        await firebase.auth().signOut();
    } catch (error) {
        console.error('Çıkış yapma hatası:', error);
        showMessage('Çıkış yapılırken hata oluştu: ' + error.message, 'error');
    }
});

// Kimlik doğrulama durumu değişikliğini dinle
firebase.auth().onAuthStateChanged((user) => {
    const authContainer = document.getElementById('auth-container');
    const appContainer = document.getElementById('app-container');

    if (user) {
        // Kullanıcı giriş yapmış
        authContainer.style.display = 'none';
        appContainer.style.display = 'block';
        loadFiles(); // Dosya listesini yükle
    } else {
        // Kullanıcı çıkış yapmış
        authContainer.style.display = 'block';
        appContainer.style.display = 'none';
    }
});

// Dosya yükleme formunu dinle
document.getElementById('upload-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const fileInput = document.getElementById('file-input');
    const file = fileInput.files[0];

    if (file) {
        await uploadFile(file);
        fileInput.value = ''; // Formu temizle
    } else {
        showMessage('Lütfen bir dosya seçin', 'error');
    }
});

// Mesaj gösterme fonksiyonu
function showMessage(message, type) {
    const messageContainer = document.getElementById('message-container');
    const messageElement = document.createElement('div');
    messageElement.className = `message ${type}`;
    messageElement.textContent = message;
    messageContainer.appendChild(messageElement);

    // 3 saniye sonra mesajı kaldır
    setTimeout(() => {
        messageElement.remove();
    }, 3000);
} 