import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart'; // TAMBAHAN PERMISSION

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  bool isFlashOn = false;
  bool isOverlayActive = true; // TAMBAHAN HOMEWORK: Status Overlay
  String? errorMessage; // Menyimpan status error untuk UI
  
  Rect? detectedBox;
  String? detectedLabel;
  Timer? _mockTimer;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndInit(); // Panggil cek izin dulu
  }

  // LOGIKA NATIVE PERMISSION (FR-V06)
  Future<void> _checkPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      errorMessage = "Izin Kamera Ditolak. Buka pengaturan untuk mengizinkan.";
      notifyListeners();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = "Tidak ada kamera yang terdeteksi.";
        notifyListeners();
        return;
      }

      controller = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
      notifyListeners();
      _startMockDetection();
    } catch (e) {
      errorMessage = "Gagal membuka kamera: $e";
      notifyListeners();
    }
  }

  void _startMockDetection() {
    _mockTimer?.cancel(); // Pastikan timer lama mati
    _mockTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final random = Random();
      detectedBox = Rect.fromLTWH(
        random.nextDouble() * 200 + 50, 
        random.nextDouble() * 300 + 100, 
        150, 100
      );
      detectedLabel = random.nextBool() ? "Pothole (D40)" : "Longitudinal Crack (D00)";
      notifyListeners();
    });
  }

  void toggleFlash() async {
    if (!isInitialized || controller == null) return;
    isFlashOn = !isFlashOn;
    await controller!.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
    notifyListeners();
  }

  // TAMBAHAN HOMEWORK: Fungsi Toggle Overlay
  void toggleOverlay() {
    isOverlayActive = !isOverlayActive;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
      isInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _checkPermissionAndInit();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mockTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }
}