import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models/log_model.dart';
import '../../services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  
  // FIX TC10: Mencegah duplikasi data saat sinkronisasi berjalan
  bool _isSyncing = false; 

  Box<LogModel> get _myBox => Hive.box<LogModel>('offline_logs');

  LogController();

  Future<void> _ensureBoxIsOpen() async {
    if (!Hive.isBoxOpen('offline_logs')) {
      await Hive.openBox<LogModel>('offline_logs');
    }
  }

  // --- 1. LOAD DATA ---
  Future<void> loadLogs(String teamId) async {
    await _ensureBoxIsOpen();
    logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();

    try {
      await Future.delayed(const Duration(seconds: 1));
      await syncOfflineLogs();
      
      final cloudData = await MongoService().getLogs(teamId);
      final stillUnsynced = _myBox.values.where((log) => log.isSynced == false).toList();
      
      await _myBox.clear();
      await _myBox.addAll(cloudData);

      for (var localLog in stillUnsynced) {
        if (!cloudData.any((c) => c.id == localLog.id)) {
          await _myBox.add(localLog);
        }
      }
      logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();
    } catch (e) {
      debugPrint("Mode Offline: Menggunakan cache lokal.");
    }
  }

  // --- 2. ADD DATA ---
  Future<void> addLog(String title, String desc, String authorId, String teamId, 
      {String category = 'Umum', bool isPublic = true, String? imagePath}) async {
    
    if (title.trim().isEmpty || desc.trim().isEmpty) return;
    if (title.length > 50) title = title.substring(0, 50);

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
      imagePath: imagePath, // <-- Tambahan untuk menampung gambar baru
    );

    try {
      await _myBox.add(newLog);
      logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();

      await MongoService().insertLog(newLog.toMap());
      
      int index = _myBox.values.toList().indexWhere((element) => element.id == newLog.id);
      if (index != -1) {
        final syncedLog = LogModel(
          id: newLog.id, title: newLog.title, description: newLog.description,
          date: newLog.date, authorId: newLog.authorId, teamId: newLog.teamId,
          isSynced: true, category: newLog.category, isPublic: newLog.isPublic,
          imagePath: newLog.imagePath, // <-- Bawa gambar saat update status sync
        );
        await _myBox.putAt(index, syncedLog);
        logsNotifier.value = _myBox.values.where((log) => log.teamId == teamId).toList();
      }
    } catch (e) {
      debugPrint("Gagal sinkron cloud, data tersimpan di lokal.");
    }
  }

  // --- 3. SYNC OFFLINE LOGS (FIX TC10: With Locking) ---
  Future<void> syncOfflineLogs() async {
    if (_isSyncing) return; // Keluar jika sedang ada proses sync jalan
    _isSyncing = true;

    try {
      await _ensureBoxIsOpen();
      final unsyncedLogs = _myBox.values.where((log) => log.isSynced == false).toList();

      for (var log in unsyncedLogs) {
        try {
          await MongoService().insertLog(log.toMap());
          
          final syncedLog = LogModel(
            id: log.id, title: log.title, description: log.description,
            date: log.date, authorId: log.authorId, teamId: log.teamId,
            isSynced: true, category: log.category, isPublic: log.isPublic,
            imagePath: log.imagePath, // <-- Bawa gambar saat offline sync
          );

          int index = _myBox.values.toList().indexWhere((element) => element.id == log.id);
          if (index != -1) await _myBox.putAt(index, syncedLog);
        } catch (e) {
          break; // Berhenti jika koneksi putus tengah jalan
        }
      }
    } finally {
      _isSyncing = false; // Buka kunci setelah selesai
    }
  }

  // --- 4. UPDATE DATA ---
  Future<void> updateLog(int index, String title, String desc, 
      {String category = 'Umum', bool isPublic = true, String? imagePath}) async {
    await _ensureBoxIsOpen();
    if (logsNotifier.value.isEmpty) return;

    final oldLog = logsNotifier.value[index];
    final updatedLog = LogModel(
      id: oldLog.id, title: title, description: desc,
      date: oldLog.date, authorId: oldLog.authorId, teamId: oldLog.teamId,
      isSynced: false, category: category, isPublic: isPublic,
      // Pertahankan gambar lama jika tidak ada gambar baru yang difoto
      imagePath: imagePath ?? oldLog.imagePath, 
    );

    int hiveIndex = _myBox.values.toList().indexWhere((element) => element.id == oldLog.id);
    if (hiveIndex != -1) {
      await _myBox.putAt(hiveIndex, updatedLog);
      logsNotifier.value = _myBox.values.where((log) => log.teamId == oldLog.teamId).toList();
      
      try {
        await MongoService().updateLog(ObjectId.fromHexString(oldLog.id!), updatedLog.toMap());
      } catch (e) {}
    }
  }

  // --- 5. REMOVE DATA ---
  Future<void> removeLog(int index, String userRole, String userId) async {
    await _ensureBoxIsOpen();
    if (logsNotifier.value.isEmpty) return;

    final target = logsNotifier.value[index];
    int hiveIndex = _myBox.values.toList().indexWhere((element) => element.id == target.id);

    if (hiveIndex != -1) {
      await _myBox.deleteAt(hiveIndex);
      logsNotifier.value = _myBox.values.where((log) => log.teamId == target.teamId).toList();
      
      try {
        await MongoService().deleteLog(ObjectId.fromHexString(target.id!));
      } catch (e) {}
    }
  }
}