import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart'; // Untuk openAppSettings

import 'vision_controller.dart';
import 'damage_painter.dart';
import 'pcd_editor_view.dart'; 

class VisionView extends StatefulWidget {
  const VisionView({super.key});
  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _vc;

  @override
  void initState() {
    super.initState();
    _vc = VisionController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: ListenableBuilder(
        listenable: _vc,
        builder: (context, _) {
          // HOMEWORK: Informative Vision State (Error)
          if (_vc.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(_vc.errorMessage!, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    child: const Text("Buka Pengaturan"),
                  )
                ],
              ),
            );
          }

          // HOMEWORK: Informative Vision State (Loading)
          if (!_vc.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke Sensor Visual...", style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 1 / _vc.controller!.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_vc.controller!),
                      
                      // HOMEWORK: Toggle Overlay Painter
                      if (_vc.isOverlayActive)
                        CustomPaint(
                          painter: DamagePainter(
                            boundingBox: _vc.detectedBox,
                            label: _vc.detectedLabel,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (_vc.isOverlayActive)
                const Positioned(
                  top: 50,
                  left: 20,
                  child: Text(
                    "AI PATROL: Searching for Road Damage...",
                    style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, backgroundColor: Colors.black54),
                  ),
                ),

              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tombol Flash
                    FloatingActionButton(
                      heroTag: "flash",
                      backgroundColor: _vc.isFlashOn ? Colors.yellow : Colors.grey[800],
                      onPressed: _vc.toggleFlash,
                      child: Icon(_vc.isFlashOn ? Icons.flash_on : Icons.flash_off, color: _vc.isFlashOn ? Colors.black : Colors.white),
                    ),
                    
                    // Tombol Jepret (PCD)
                    FloatingActionButton(
                      heroTag: "capture",
                      backgroundColor: Colors.red,
                      onPressed: () async {
                        final image = await _vc.controller!.takePicture();
                        final dir = await getApplicationDocumentsDirectory();
                        final path = p.join(dir.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");
                        await File(image.path).copy(path);
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => PcdEditorView(imagePath: path),
                          ));
                        }
                      },
                      child: const Icon(Icons.science, color: Colors.white),
                    ),

                    // HOMEWORK: Tombol Toggle Overlay
                    FloatingActionButton(
                      heroTag: "overlay",
                      backgroundColor: _vc.isOverlayActive ? Colors.teal : Colors.grey[800],
                      onPressed: _vc.toggleOverlay,
                      child: Icon(_vc.isOverlayActive ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}