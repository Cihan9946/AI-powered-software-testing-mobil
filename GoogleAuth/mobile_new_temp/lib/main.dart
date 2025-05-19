import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService(prefs);
  final apiService = ApiService(prefs);
  
  runApp(MyApp(
    authService: authService,
    apiService: apiService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final ApiService apiService;

  const MyApp({
    Key? key,
    required this.authService,
    required this.apiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobil Uygulama',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasData) {
              return HomeScreen(
                authService: authService,
                apiService: apiService,
              );
            }
            
            return LoginScreen(authService: authService);
          },
        ),
        '/login': (context) => LoginScreen(authService: authService),
        '/home': (context) => HomeScreen(
          authService: authService,
          apiService: apiService,
        ),
      },
    );
  }
}
