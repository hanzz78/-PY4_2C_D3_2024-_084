import 'package:flutter_test/flutter_test.dart';
// Ganti path import di bawah ini sesuai dengan nama project kamu
import '../lib/features/auth/login_controller.dart'; 

void main() {
  group('LoginController Unit Test', () {
    late LoginController controller;

    setUp(() {
      controller = LoginController();
    });

    // --- TEST MODULE: LOGIN (POSITIF) ---
    test('TC01: Valid Login - Admin', () {
      expect(controller.login("admin", "123"), true);
    });

    test('TC02: Valid Login - User084', () {
      expect(controller.login("user084", "pass084"), true);
    });

    test('TC03: Valid Login - Mahasiswa', () {
      expect(controller.login("mahasiswa", "praktek2026"), true);
    });

    // --- TEST MODULE: LOGIN (NEGATIF) ---
    test('TC04: Empty Username', () {
      expect(controller.login("", "123"), false);
    });

    test('TC05: Empty Password', () {
      expect(controller.login("admin", ""), false);
    });

    test('TC06: Wrong Password', () {
      expect(controller.login("admin", "salah_pass"), false);
    });

    test('TC07: Non-existent User', () {
      expect(controller.login("siapa_ini", "123"), false);
    });

    // --- TEST MODULE: ISLOCKED (POSITIF & NEGATIF) ---
    test('TC08: Initially Not Locked', () {
      expect(controller.isLocked, false);
    });

    test('TC09: Lock After 3 Failed Attempts', () {
      controller.login("admin", "salah");
      controller.login("admin", "salah");
      controller.login("admin", "salah");
      expect(controller.isLocked, true);
    });

    // --- TARGET BUG: TEST CASE 10 ---
    test('TC10: Should Not Be Locked After Only 2 Failed Attempts', () {
      controller.login("admin", "salah");
      controller.login("admin", "salah");
      
      // Ini akan FAILED karena bug di kode: _salahLog >= 2
      // Ekspektasi: false (belum kunci), Aktual: true (sudah kunci)
      expect(controller.isLocked, false);
    });
  });
}