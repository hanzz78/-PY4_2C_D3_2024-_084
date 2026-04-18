import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_084/features/logbook/logbook_controller.dart';
import 'package:logbook_app_084/features/logbook/models/log_model.dart';
import 'dart:io';

void main() {
  group('LogController Unit Test (9 Pass, 1 Fail)', () {
    late LogController controller;
    const String testBoxName = 'offline_logs';

    setUp(() async {
      // Inisialisasi Hive untuk Testing
      final tempDir = Directory.systemTemp.createTempSync();
      Hive.init(tempDir.path);
      
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LogModelAdapter());
      }
      
      await Hive.openBox<LogModel>(testBoxName);
      controller = LogController();
    });

    tearDown(() async {
      await Hive.box<LogModel>(testBoxName).clear();
      await Hive.close();
    });

    test('TC01: Initial State Empty', () {
      expect(controller.logsNotifier.value.isEmpty, true);
    });

    test('TC02: Prevent Empty Title', () async {
      // Pengujian ini akan Pass jika kamu menambah validasi if(title.isEmpty) return;
      await controller.addLog("", "Deskripsi", "user1", "team1");
      expect(controller.logsNotifier.value.length, 0);
    });

    test('TC03: Save Log to Hive Disk', () async {
      await controller.addLog("Belajar Flutter", "Isi Deskripsi", "user1", "team1");
      expect(controller.logsNotifier.value.any((log) => log.title == "Belajar Flutter"), true);
    });

    test('TC04: Auto Timestamp Check', () async {
      await controller.addLog("Test Time", "Content", "user1", "team1");
      expect(controller.logsNotifier.value.first.date, isNotNull);
    });

    test('TC05: Delete Log from Disk', () async {
      await controller.addLog("Hapus Me", "Content", "user1", "team1");
      await controller.removeLog(0, "admin", "user1");
      expect(controller.logsNotifier.value.length, 0);
    });

    test('TC06: Reject Empty Content', () async {
      await controller.addLog("Judul Ada", "", "user1", "team1");
      expect(controller.logsNotifier.value.length, 0);
    });

    test('TC07: Update Existing Log', () async {
      await controller.addLog("Judul Lama", "Konten", "user1", "team1");
      await controller.updateLog(0, "Judul Baru", "Konten Baru");
      expect(controller.logsNotifier.value.first.title, "Judul Baru");
    });

    test('TC08: Search Functionality Simulation', () async {
      await controller.addLog("Cari Saya", "Konten", "user1", "team1");
      final results = controller.logsNotifier.value.where((l) => l.title.contains("Cari")).toList();
      expect(results.length, 1);
    });

    test('TC09: Data Persistence Check', () async {
      await controller.addLog("Data Persis", "Konten", "user1", "team1");
      expect(Hive.box<LogModel>(testBoxName).isNotEmpty, true);
    });

    // --- TEST CASE 10: INI AKAN FAILED (MERAH) ---
    test('TC10: Max Title Length Validation', () async {
      // Membuat judul sepanjang 60 karakter
      String longTitle = "A" * 60; 
      
      await controller.addLog(longTitle, "Deskripsi", "user1", "team1");
      
      // Ekspektasi: Panjang judul tidak boleh lebih dari 50
      // Aktual: Karena bug di controller, judul akan tersimpan 60 karakter
      // Hasil: Test FAILED
      expect(controller.logsNotifier.value.first.title.length <= 50, true);
    });
  });
}