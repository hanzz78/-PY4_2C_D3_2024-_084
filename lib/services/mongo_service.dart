import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../helpers/log_helper.dart';
import '../features/logbook/models/log_model.dart'; 

class MongoService {
  // [SINGLETON] Memastikan hanya ada satu koneksi database di seluruh aplikasi
  static final MongoService _instance = MongoService._internal();
  Db? _db;
  DbCollection? _collection;

  factory MongoService() => _instance;

  MongoService._internal();

  // Fungsi untuk menghubungkan ke MongoDB Atlas
  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) throw Exception("MONGODB_URI tidak ditemukan di .env");

      _db = await Db.create(dbUri);
      await _db!.open();
      
      // Koleksi 'logs' pada klaster raihan084
      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Terhubung ke MongoDB Atlas",
        source: "mongo_service.dart",
        level: 2, // INFO
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Terhubung - $e",
        source: "mongo_service.dart",
        level: 1, // ERROR
      );
      rethrow;
    }
  }

  Future<void> updateLog(ObjectId id, Map<String, dynamic> data) async {
  try {
    // Menggunakan modifier $set agar hanya field tertentu yang berubah
    await _collection!.update(
      where.id(id),
      {
        '\$set': {
          'title': data['title'],
          'description': data['description'],
          'category': data['category'],
          'date': DateTime.now().toString(),
        }
      },
    );
    await LogHelper.writeLog("DATABASE: Berhasil memperbarui dokumen $id", source: "mongo_service.dart");
  } catch (e) {
    print("Error updateLog: $e");
  }
}

  // Ambil data (Read) dengan konversi ke List<LogModel>
Future<List<LogModel>> getLogs() async {
  try {
    // 1. Cek apakah database sudah terhubung dan terbuka
    if (_db == null || !_db!.isConnected) {
      print("DATABASE: Tidak ada koneksi aktif, mencoba hubungkan kembali...");
      await connect(); // Coba connect ulang jika putus
    }

    if (_collection == null) return [];
    
    final data = await _collection!.find().toList();
    return data.map((item) => LogModel.fromMap(item)).toList();
  } catch (e) {
    // 2. Jika gagal karena offline, lempar error agar ditangkap FutureBuilder
    print("Error getLogs: $e");
    throw Exception("Koneksi internet bermasalah"); 
  }
}

  // Simpan data (Create)
Future<void> insertLog(Map<String, dynamic> data) async {
  try {
    // Pastikan koneksi tidak null sebelum insert
    if (_collection == null) {
      print("ERROR: Koleksi belum terinisialisasi. Mencoba hubungkan ulang...");
      await connect();
    }
    
    final result = await _collection!.insert(data);
    print("LOG: Hasil insert ke MongoDB -> $result"); // Lihat ini di terminal!
    
    await LogHelper.writeLog(
      "DATABASE: Berhasil simpan catatan baru",
      source: "mongo_service.dart",
    );
  } catch (e) {
    print("ERROR DATABASE: Gagal Simpan - $e");
    await LogHelper.writeLog("DATABASE: Gagal Simpan - $e", level: 1);
  }
}

  // Menambahkan fungsi Hapus data (Delete) yang diminta di UI
  Future<void> deleteLog(ObjectId id) async {
    try {
      await _collection!.remove(where.id(id));
      await LogHelper.writeLog(
        "DATABASE: Berhasil menghapus dokumen dengan ID $id",
        source: "mongo_service.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal menghapus - $e",
        source: "mongo_service.dart",
      );
    }
  }

  // Tutup koneksi
  Future<void> close() async {
    await _db?.close();
  }
}