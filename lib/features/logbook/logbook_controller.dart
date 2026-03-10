import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models/log_model.dart';
import '../../services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  // Safety Getter: Memastikan box selalu tersedia
  Box<LogModel> get _myBox => Hive.box<LogModel>('offline_logs');

  LogController();

  // Helper untuk memastikan box terbuka sebelum eksekusi (Anti Box Not Found)
  Future<void> _ensureBoxIsOpen() async {
    if (!Hive.isBoxOpen('offline_logs')) {
      await Hive.openBox<LogModel>('offline_logs');
    }
  }

  // --- FUNGSI SYNC: Penyetor data yang tertunda ---
  Future<void> syncOfflineLogs() async {
    await _ensureBoxIsOpen();
    // Ambil data yang isSynced-nya FALSE
    final unsyncedLogs = _myBox.values.where((log) => log.isSynced == false).toList();

    if (unsyncedLogs.isEmpty) return;

    debugPrint("SYNC: Ditemukan ${unsyncedLogs.length} data tertunda. Menyetor ke cloud...");

    for (var log in unsyncedLogs) {
      try {
        // Kirim ke MongoDB Atlas
        await MongoService().insertLog(log.toMap());

        // Jika berhasil, update status di Hive jadi TRUE
        final syncedLog = LogModel(
          id: log.id,
          title: log.title,
          description: log.description,
          date: log.date,
          authorId: log.authorId,
          teamId: log.teamId,
          isSynced: true, 
          category: log.category,
          isPublic: log.isPublic, // Tetap jaga privasi saat sync
        );

        // Cari index aslinya di Hive untuk ditimpa
        int hiveIndex = _myBox.values.toList().indexWhere((element) => element.id == log.id);
        if (hiveIndex != -1) {
          await _myBox.putAt(hiveIndex, syncedLog);
        }
      } catch (e) {
        debugPrint("SYNC ERROR: Gagal setor ${log.title}. Koneksi mungkin tidak stabil.");
        break; // Stop loop jika koneksi bermasalah
      }
    }
  }

  // --- 1. LOAD DATA: Strategi Offline-First dengan Anti-Data-Loss ---
  Future<void> loadLogs(String teamId) async {
    await _ensureBoxIsOpen();
    
    // Langkah A: Tampilkan data lokal segera (Instan)
    logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();

    try {
      // Jeda 1 detik agar koneksi MongoService benar-benar 'Ready'
      await Future.delayed(const Duration(seconds: 1));
      
      // Langkah B: Setor dulu data yang tadi dibuat/diubah pas offline
      await syncOfflineLogs();

      // Langkah C: Ambil data terbaru dari Cloud yang sudah paling update
      final cloudData = await MongoService().getLogs(teamId);
      
      // LOGIKA ANTI HILANG: Amankan data yang masih oranye
      final stillUnsynced = _myBox.values.where((log) => log.isSynced == false).toList();
      
      await _myBox.clear();
      await _myBox.addAll(cloudData);

      // Masukkan kembali data offline yang (tadi) gagal dikirim
      for (var localLog in stillUnsynced) {
        // Hanya masukkan jika belum ada di cloudData (mencegah duplikat)
        if (!cloudData.any((c) => c.id == localLog.id)) {
          await _myBox.add(localLog);
        }
      }

      // Update UI dengan gabungan data Cloud + Data Offline sisa
      logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();
      
    } catch (e) {
      debugPrint("OFFLINE: Mempertahankan data cache lokal.");
      logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();
    }
  }

  // --- 2. ADD DATA ---
  Future<void> addLog(String title, String desc, String authorId, String teamId, 
      {String category = 'Umum', bool isPublic = true}) async {
    await _ensureBoxIsOpen();

    final newLog = LogModel(
      id: ObjectId().oid, 
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      isSynced: false,
      category: category,
      isPublic: isPublic, 
    );

    try {
      // Simpan Lokal
      await _myBox.add(newLog);
      logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();

      // Kirim ke Cloud
      await MongoService().insertLog(newLog.toMap());
      
      // Jika sukses, ubah status jadi true
      int index = _myBox.values.toList().indexWhere((element) => element.id == newLog.id);
      if (index != -1) {
        final syncedLog = LogModel(
          id: newLog.id, title: newLog.title, description: newLog.description,
          date: newLog.date, authorId: newLog.authorId, teamId: newLog.teamId,
          isSynced: true, category: newLog.category, isPublic: newLog.isPublic,
        );
        await _myBox.putAt(index, syncedLog);
        logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();
      }
    } catch (e) {
      debugPrint("Gagal sinkron instan. Data aman di lokal.");
    }
  }

  // --- 3. UPDATE DATA ---
  Future<void> updateLog(int index, String title, String desc, 
      {String category = 'Umum', bool isPublic = true}) async {
    await _ensureBoxIsOpen();
    final oldLog = logsNotifier.value[index];

    final updatedLog = LogModel(
      id: oldLog.id, title: title, description: desc,
      date: oldLog.date, authorId: oldLog.authorId, teamId: oldLog.teamId,
      isSynced: false, category: category, isPublic: isPublic,
    );

    int hiveIndex = _myBox.values.toList().indexWhere((element) => element.id == oldLog.id);
    
    if (hiveIndex != -1) {
      await _myBox.putAt(hiveIndex, updatedLog);
      logsNotifier.value = _myBox.values.where((log) => log.teamId == oldLog.teamId).toList();

      try {
        // Setor ke cloud
        await MongoService().updateLog(ObjectId.fromHexString(oldLog.id!), updatedLog.toMap());
        
        final finalizedLog = LogModel(
          id: updatedLog.id, title: updatedLog.title, description: updatedLog.description,
          date: updatedLog.date, authorId: updatedLog.authorId, teamId: updatedLog.teamId,
          isSynced: true, category: updatedLog.category, isPublic: updatedLog.isPublic,
        );
        await _myBox.putAt(hiveIndex, finalizedLog);
        logsNotifier.value = _myBox.values.where((log) => log.teamId == oldLog.teamId).toList();
      } catch (e) {
        debugPrint("Gagal update cloud.");
      }
    }
  }

  // --- 4. REMOVE DATA ---
  Future<void> removeLog(int index, String userRole, String userId) async {
    await _ensureBoxIsOpen();
    final target = logsNotifier.value[index];
    int hiveIndex = _myBox.values.toList().indexWhere((element) => element.id == target.id);

    if (hiveIndex != -1) {
      await _myBox.deleteAt(hiveIndex);
      try {
        await MongoService().deleteLog(ObjectId.fromHexString(target.id!));
      } catch (e) {
        debugPrint("Gagal hapus di Cloud.");
      }
      loadLogs(target.teamId); 
    }
  }
}