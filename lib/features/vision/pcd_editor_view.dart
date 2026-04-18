import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math; // TAMBAHAN: Untuk generator angka acak (Noise)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'package:image/image.dart' as img; 

class PcdEditorView extends StatefulWidget {
  final String imagePath;
  const PcdEditorView({super.key, required this.imagePath});

  @override
  State<PcdEditorView> createState() => _PcdEditorViewState();
}

class _PcdEditorViewState extends State<PcdEditorView> {
  String _selectedFilter = 'lowpass';
  Uint8List? _processedImageBytes;
  bool _isLoading = false;

  // Daftar Filter PCD Lengkap + Noise
  final Map<String, String> _filters = {
    'lowpass': 'Low-pass (Gaussian Blur)',
    'highpass': 'High-pass (Deteksi Tepi)',
    'bandpass': 'Band-pass Filter',
    'mean': 'Mean Filter (Box Blur)',
    'median': 'Median Filter (Hapus Noise)',
    'histogram_eq': 'Histogram Equalization',
    'noise': 'Uniform Noise (Bintik Acak)',
    'salt_pepper': 'Salt & Pepper (Hitam & Putih)',
  };

  Future<void> _processImageNative() async {
    setState(() => _isLoading = true);
    
    try {
      final processedBytes = await compute(_applyFilterInBackground, {
        'path': widget.imagePath,
        'filter': _selectedFilter,
      });

      if (processedBytes != null) {
        setState(() => _processedImageBytes = processedBytes);
      } else {
        _showToast("Gagal memproses gambar.");
      }
    } catch (e) {
      debugPrint("Error PCD Native: $e");
      _showToast("Terjadi kesalahan komputasi matriks.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_processedImageBytes == null) return;
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        _processedImageBytes!,
        quality: 100,
        name: "PCD_Advanced_${DateTime.now().millisecondsSinceEpoch}",
      );
      
      if (result['isSuccess']) {
        _showToast("Berhasil di-download ke Galeri!");
      } else {
        _showToast("Gagal menyimpan gambar.");
      }
    } catch (e) {
      _showToast("Terjadi kesalahan saat menyimpan.");
    }
  }

  void _showToast(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laboratorium PCD"),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_processedImageBytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Download",
              onPressed: _saveToGallery,
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black12,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: _processedImageBytes != null
                  ? Image.memory(_processedImageBytes!, fit: BoxFit.contain)
                  : Image.file(File(widget.imagePath), fit: BoxFit.contain),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Pilih Algoritma Konvolusi/Noise:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _filters.entries.map((e) => 
                    DropdownMenuItem(value: e.key, child: Text(e.value))
                  ).toList(),
                  onChanged: (val) => setState(() => _selectedFilter = val!),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _processImageNative,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.calculate),
                  label: Text(_isLoading ? "Menghitung Matriks..." : "Terapkan Algoritma"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// ISOLATE: ALGORITMA PENGOLAHAN CITRA DIGITAL (MANUAL DART)
// =========================================================================
Future<Uint8List?> _applyFilterInBackground(Map<String, dynamic> params) async {
  final String path = params['path'];
  final String filterType = params['filter'];

  final File file = File(path);
  final Uint8List bytes = await file.readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) return null;

  // Perkecil gambar agar komputasi matriks di CPU HP tidak overload
  if (image.width > 800) {
    image = img.copyResize(image, width: 800);
  }

  // Siapkan instansiasi random generator untuk Noise
  final math.Random rand = math.Random();

  switch (filterType) {
    case 'lowpass':
      image = img.gaussianBlur(image, radius: 4); 
      break;

    case 'mean':
      image = img.convolution(image, filter: [1, 1, 1, 1, 1, 1, 1, 1, 1], div: 9);
      break;

    case 'highpass':
      image = img.convolution(image, filter: [-1, -1, -1, -1, 8, -1, -1, -1, -1]);
      break;

    case 'bandpass':
      image = img.gaussianBlur(image, radius: 3);
      image = img.convolution(image, filter: [-1, -1, -1, -1, 8, -1, -1, -1, -1]);
      break;

    case 'noise':
      // UNIFORM NOISE: Menambahkan atau mengurangkan nilai acak pada setiap RGB piksel
      for (final p in image) {
        // Rentang noise: -40 hingga +40
        int noiseVal = rand.nextInt(81) - 40; 
        
        p.r = (p.r + noiseVal).clamp(0, 255);
        p.g = (p.g + noiseVal).clamp(0, 255);
        p.b = (p.b + noiseVal).clamp(0, 255);
      }
      break;

    case 'salt_pepper':
      // SALT & PEPPER: Secara acak menimpa piksel menjadi murni Putih (255) atau Hitam (0)
      for (final p in image) {
        int chance = rand.nextInt(100); // Peluang 0 - 99
        
        if (chance < 3) {
          // 3% kemungkinan piksel jadi Salt (Garam / Putih)
          p.r = 255;
          p.g = 255;
          p.b = 255;
        } else if (chance < 6) {
          // 3% kemungkinan piksel jadi Pepper (Lada / Hitam)
          p.r = 0;
          p.g = 0;
          p.b = 0;
        }
        // Sisa 94% piksel dibiarkan normal
      }
      break;

    case 'median':
      image = img.grayscale(image); 
      img.Image temp = image.clone();
      
      for (int y = 1; y < image.height - 1; y++) {
        for (int x = 1; x < image.width - 1; x++) {
          List<num> window = []; // Gunakan tipe data 'num' agar aman
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              window.add(temp.getPixel(x + dx, y + dy).r);
            }
          }
          window.sort(); 
          num medianVal = window[4]; 
          image.setPixelRgb(x, y, medianVal, medianVal, medianVal);
        }
      }
      break;

    case 'histogram_eq':
      image = img.grayscale(image);
      
      List<int> hist = List.filled(256, 0);
      for (final p in image) {
        hist[p.r.toInt()]++;
      }
      
      List<int> cdf = List.filled(256, 0);
      cdf[0] = hist[0];
      for (int i = 1; i < 256; i++) cdf[i] = cdf[i - 1] + hist[i];
      
      int minCdf = cdf.firstWhere((val) => val > 0);
      int totalPixels = image.width * image.height;
      
      for (final p in image) {
        int v = p.r.toInt();
        int h = (((cdf[v] - minCdf) / (totalPixels - minCdf)) * 255).round().clamp(0, 255);
        p.r = h;
        p.g = h;
        p.b = h;
      }
      break;
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}