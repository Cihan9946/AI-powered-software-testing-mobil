// Firestore referansını oluştur
const db = firebase.firestore();
const uploadsCollection = db.collection('uploads');

// Dosya yükleme fonksiyonu
async function uploadFile(file) {
    try {
        const user = firebase.auth().currentUser;
        if (!user) {
            throw new Error('Kullanıcı girişi yapılmamış');
        }

        // Dosyayı yükle
        const storageRef = firebase.storage().ref();
        const fileRef = storageRef.child(`uploads/${user.uid}/${file.name}`);
        await fileRef.put(file);

        // Firestore'a kaydet
        await uploadsCollection.add({
            user: user.email,
            zip_name: file.name,
            upload_time: firebase.firestore.FieldValue.serverTimestamp(),
            extracted_path: `uploads/${user.uid}/${file.name}`,
            bandit_results: {},
            ai_results: {}
        });

        // Başarılı mesajı göster
        showMessage('Dosya başarıyla yüklendi', 'success');
        
        // Dosya listesini güncelle
        loadFiles();
    } catch (error) {
        console.error('Dosya yükleme hatası:', error);
        showMessage('Dosya yüklenirken hata oluştu: ' + error.message, 'error');
    }
}

// Dosyaları listele
async function loadFiles() {
    try {
        const user = firebase.auth().currentUser;
        if (!user) {
            throw new Error('Kullanıcı girişi yapılmamış');
        }

        const filesList = document.getElementById('filesList');
        filesList.innerHTML = '';

        const snapshot = await uploadsCollection
            .where('user', '==', user.email)
            .orderBy('upload_time', 'desc')
            .get();

        if (snapshot.empty) {
            filesList.innerHTML = '<p>Henüz yüklenmiş dosya yok.</p>';
            return;
        }

        snapshot.forEach(doc => {
            const data = doc.data();
            const fileItem = document.createElement('div');
            fileItem.className = 'file-item';
            fileItem.innerHTML = `
                <div class="file-info">
                    <h3>${data.zip_name}</h3>
                    <p>Yüklenme: ${data.upload_time ? new Date(data.upload_time.toDate()).toLocaleString() : 'Bilinmiyor'}</p>
                </div>
                <div class="file-actions">
                    <button onclick="viewReport('${doc.id}')" class="btn btn-primary">Raporu Görüntüle</button>
                    <button onclick="deleteFile('${doc.id}')" class="btn btn-danger">Sil</button>
                </div>
            `;
            filesList.appendChild(fileItem);
        });
    } catch (error) {
        console.error('Dosya listesi yükleme hatası:', error);
        showMessage('Dosya listesi yüklenirken hata oluştu: ' + error.message, 'error');
    }
}

// Dosya silme fonksiyonu
async function deleteFile(docId) {
    try {
        await uploadsCollection.doc(docId).delete();
        showMessage('Dosya başarıyla silindi', 'success');
        loadFiles();
    } catch (error) {
        console.error('Dosya silme hatası:', error);
        showMessage('Dosya silinirken hata oluştu: ' + error.message, 'error');
    }
}

// Rapor görüntüleme fonksiyonu
async function viewReport(docId) {
    try {
        const doc = await uploadsCollection.doc(docId).get();
        if (doc.exists) {
            const data = doc.data();
            // Rapor sayfasına yönlendir
            window.location.href = `/report.html?id=${docId}`;
        }
    } catch (error) {
        console.error('Rapor görüntüleme hatası:', error);
        showMessage('Rapor görüntülenirken hata oluştu: ' + error.message, 'error');
    }
} 