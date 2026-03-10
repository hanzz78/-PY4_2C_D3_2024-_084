import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../helpers/log_helper.dart';
import '../features/logbook/models/log_model.dart'; 

class MongoService {
  static final MongoService _instance = MongoService._internal();
  Db? _db;
  DbCollection? _collection;
  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  Future<void> _ensureConnected() async {
    if (_db == null || !_db!.isConnected) {
      await LogHelper.writeLog("DATABASE: Mencoba menyambungkan ulang...", source: _source, level: 2);
      await connect();
    }
  }

  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) throw Exception("MONGODB_URI tidak ditemukan di .env");

      _db = await Db.create(dbUri);
      await _db!.open();
      
      _collection = _db!.collection('logs');
      await LogHelper.writeLog("DATABASE: Terhubung ke MongoDB Atlas", source: _source, level: 2);
    } catch (e) {
      await LogHelper.writeLog("DATABASE: Gagal Terhubung - $e", source: _source, level: 1);
      rethrow;
    }
  }

  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      await _ensureConnected();
      if (_collection == null) return [];
      
      final List<Map<String, dynamic>> data = await _collection!
          .find(where.eq('teamId', teamId)) 
          .toList();

      return data.map((item) => LogModel.fromMap(item)).toList();
    } catch (e) {
      print("Error getLogs: $e");
      return []; 
    }
  }

  // FIX: Sekarang status privasi (isPublic) ikut tersimpan ke Cloud
  Future<void> updateLog(ObjectId id, Map<String, dynamic> data) async {
    try {
      await _ensureConnected();
      await _collection!.update(
        where.id(id),
        {
          '\$set': {
            'title': data['title'],
            'description': data['description'],
            'date': DateTime.now().toString(),
            'authorId': data['authorId'],
            'teamId': data['teamId'],
            'category': data['category'],
            'isPublic': data['isPublic'], // BARIS INI WAJIB ADA!
          }
        },
      );
      await LogHelper.writeLog("DATABASE: Berhasil memperbarui dokumen $id", source: _source);
    } catch (e) {
      print("Error updateLog: $e");
      rethrow;
    }
  }

  Future<void> insertLog(Map<String, dynamic> data) async {
    try {
      await _ensureConnected();
      await _collection!.insert(data);
      await LogHelper.writeLog("DATABASE: Berhasil simpan catatan baru", source: _source);
    } catch (e) {
      await LogHelper.writeLog("DATABASE: Gagal Simpan - $e", level: 1);
      rethrow;
    }
  }

  Future<void> deleteLog(ObjectId id) async {
    try {
      await _ensureConnected();
      await _collection!.remove(where.id(id));
      await LogHelper.writeLog("DATABASE: Berhasil menghapus dokumen $id", source: _source);
    } catch (e) {
      await LogHelper.writeLog("DATABASE: Gagal menghapus - $e", level: 1);
      rethrow;
    }
  }

  Future<void> close() async {
    await _db?.close();
  }
}