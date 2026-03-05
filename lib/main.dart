import 'package:flutter/material.dart';
import 'package:logbook_app_084/features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_084/services/mongo_service.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tambahkan ini

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal bahasa Indonesia
  await initializeDateFormatting('id', null);

  try {
    await dotenv.load(fileName: ".env");
    final mongoService = MongoService();
    await mongoService.connect(); 
  } catch (e) {
    debugPrint("Koneksi gagal: $e");
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