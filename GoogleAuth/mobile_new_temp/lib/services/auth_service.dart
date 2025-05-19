import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  // Kullanıcının giriş durumunu kontrol et
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google ile giriş yap
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-In işlemini başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      // Google kimlik bilgilerini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase kimlik bilgilerini oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase ile giriş yap
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Kullanıcı bilgilerini kaydet
      if (userCredential.user != null) {
        await _prefs.setString('user_email', userCredential.user!.email ?? '');
        await _prefs.setString('user_name', userCredential.user!.displayName ?? '');
        await _prefs.setString('user_photo', userCredential.user!.photoURL ?? '');
      }

      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _prefs.clear();
  }

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;
} 