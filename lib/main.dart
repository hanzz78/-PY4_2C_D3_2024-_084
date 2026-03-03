import 'package:flutter/material.dart';
import 'package:logbook_app_084/features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Tambahkan ini
import 'package:logbook_app_084/services/mongo_service.dart'; // Pastikan path benar

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    final mongoService = MongoService();
    await mongoService.connect(); // Pastikan koneksi Atlas berhasil
  } catch (e) {
    debugPrint("Koneksi gagal: $e"); // Gunakan debugPrint agar tidak melanggar linting
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
      ),
      home: const OnboardingView(),
    );
  }
}
