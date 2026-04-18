**Oleh:** Muhammad Raihan Abubakar (241511084)

## Fitur Utama
1. **Live Camera & Overlay (Modul 6):** Akses sensor kamera dengan *AppLifecycleState* untuk mencegah *memory leak*.
2. **Mock AI Detector:** Simulasi *bounding box* presisi tinggi menggunakan *Logical Pixels* dan *CustomPainter*.
3. **Hardware Control:** Pengendalian lampu senter (Flash/Torch) secara sinkron.
4. **Laboratorium PCD Offline:** 8 algoritma manipulasi piksel mandiri tanpa API eksternal (termasuk *Gaussian Blur*, *High-pass*, *Median Filter*, dan *Histogram Equalization*).

## Persyaratan Sistem
* **Flutter SDK:** Versi 3.x ke atas.
* **Perangkat Tes:** Direkomendasikan menggunakan *Real Device* (HP Android fisik) karena fitur Kamera dan Flashlight sering kali tidak stabil di Emulator bawaan.
* **Koneksi Internet:** Hanya dibutuhkan saat proses *login* awal (MongoDB). Pengolahan citra (PCD) berjalan 100% *offline*.

## Panduan Instalasi dan Menjalankan Aplikasi

**Langkah 1: Persiapan Folder**
Ekstrak file `.zip` ini ke direktori lokal Anda. Buka terminal di dalam folder tersebut.

**Langkah 2: Unduh Dependensi**
Jalankan perintah berikut untuk mengunduh pustaka (seperti `camera`, `permission_handler`, dan `image`):
`flutter pub get`

**Langkah 3: Konfigurasi Database (Penting!)**
Aplikasi ini terhubung dengan MongoDB Atlas. Karena sistem keamanan *IP Whitelisting*, Anda mungkin tidak bisa *login* jika IP jaringan Anda belum terdaftar.
1. Buka MongoDB Atlas.
2. Masuk ke menu **Network Access**.
3. Tambahkan IP `0.0.0.0/0` (Allow Access From Anywhere).

**Langkah 4: Jalankan Aplikasi**
Pastikan HP Android sudah tersambung dengan mode *USB Debugging* aktif. Jalankan perintah:
`flutter run`

## Catatan Performa (PCD)
Filter *Median* dan *Histogram Equalization* memproses ratusan ribu piksel secara manual. Aplikasi mungkin akan memuat selama 2-5 detik saat menerapkan algoritma ini. Proses ini menggunakan `Isolate` (Background Thread) sehingga antarmuka utama (UI) tidak akan mengalami *freeze*.
