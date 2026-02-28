import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  // Untuk Homework: List untuk hasil filter
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  
  static const String _storageKey = 'user_logs_data';

  LogController() { loadFromDisk(); }

  // --- LOGIKA FILTER (HOMEWORK 1) ---
  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  // --- MODIFIKASI CRUD UNTUK SINKRONISASI ---
  
  void addLog(String title, String desc, String category) {
    final newLog = LogModel(
      title: title, 
      description: desc, 
      date: DateTime.now().toString(),
      category: category, // Tambahkan kategori
    );
    logsNotifier.value = [...logsNotifier.value, newLog];
    _refreshFilter(); // Pastikan list filter terupdate
    saveToDisk();
  }

  void updateLog(int index, String title, String desc, String category) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = LogModel(
      title: title, 
      description: desc, 
      date: DateTime.now().toString(),
      category: category,
    );
    logsNotifier.value = currentLogs;
    _refreshFilter();
    saveToDisk();
  }

  void removeLog(int index) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    _refreshFilter();
    saveToDisk();
  }

  // Helper agar tidak menulis searchLog("") berulang kali
  void _refreshFilter() {
    filteredLogs.value = logsNotifier.value;
  }

  // --- PERSISTENCE (TASK 4 & HOMEWORK 3) ---

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(logsNotifier.value.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
      _refreshFilter(); // Isi filteredLogs setelah data dimuat
    }
  }
}