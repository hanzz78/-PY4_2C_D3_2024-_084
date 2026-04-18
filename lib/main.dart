import 'package:flutter/material.dart';
import 'package:logbook_app_084/features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_084/services/mongo_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:logbook_app_084/features/logbook/models/log_model.dart'; 

// 1. TAMBAHKAN IMPORT KAMERA DI SINI
import 'package:camera/camera.dart'; 

// 2. BUAT VARIABEL GLOBAL UNTUK LIST KAMERA
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('id', null);

  // 3. INISIALISASI KAMERA (Wajib dilakukan sebelum masuk ke Hive/Mongo)
  try {
    cameras = await availableCameras();
    debugPrint("CAMERA: ${cameras.length} kamera ditemukan.");
  } on CameraException catch (e) {
    debugPrint('CAMERA ERROR: ${e.code}\nMessage: ${e.description}');
  }

  try {
    // 1. Load Env
    await dotenv.load(fileName: ".env");

    // 2. Inisialisasi Hive
    await Hive.initFlutter();
    
    // 3. Registrasi Adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LogModelAdapter()); 
    }

    // 4. Buka Box dengan pengecekan ekstra
    if (!Hive.isBoxOpen('offline_logs')) {
      await Hive.openBox<LogModel>('offline_logs');
    }
    debugPrint("HIVE: Box 'offline_logs' berhasil dibuka.");

    // 5. Hubungkan ke MongoDB Atlas (Non-blocking)
    MongoService().connect().catchError((e) {
      debugPrint("MONGODB ERROR: $e");
    });
    
  } catch (e) {
    debugPrint("INISIALISASI UTAMA ERROR: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OnboardingView(),
    );
  }
}