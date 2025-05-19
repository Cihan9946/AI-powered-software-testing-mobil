// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_new_temp/main.dart';
import 'package:mobile_new_temp/services/auth_service.dart';
import 'package:mobile_new_temp/services/api_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // SharedPreferences instance oluştur
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    // Servisleri oluştur
    final authService = AuthService(prefs);
    final apiService = ApiService(prefs);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      authService: authService,
      apiService: apiService,
    ));

    // Login ekranının yüklendiğini kontrol et
    expect(find.text('Hoş Geldiniz'), findsOneWidget);
  });
}
