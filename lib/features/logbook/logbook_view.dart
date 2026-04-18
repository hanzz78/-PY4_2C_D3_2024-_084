import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'logbook_controller.dart'; 
import 'log_editor_page.dart'; 
import 'models/log_model.dart';
import '../auth/login_view.dart';
import '../vision/vision_view.dart'; 
// TAMBAHAN WAJIB: Import halaman Lab PCD yang baru kita buat
import '../vision/pcd_editor_view.dart'; 

class LogbookView extends StatefulWidget {
  final String username;
  final String userId;
  final String teamId;

  const LogbookView({
    super.key,
    required this.username,
    required this.userId,
    required this.teamId,
  });

  @override
  State<LogbookView> createState() => _LogbookViewState();
}

class _LogbookViewState extends State<LogbookView> {
  late final LogController _controller;
  String _searchQuery = ""; 
  String _filterCategory = "Semua";

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _controller = LogController();
    _controller.loadLogs(widget.teamId);
  }

  Color _getHomeworkColor(String category) {
    switch (category) {
      case 'Mechanical': return Colors.green.shade600;
      case 'Electronic': return Colors.blue.shade600;
      case 'Software': return Colors.purple.shade600;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.indigo.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text(
            "Belum ada aktivitas hari ini?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const Text(
            "Mulai catat kemajuan proyek Anda!",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(innerContext), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(innerContext);
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id').format(dateTime);
    } catch (e) { return dateStr; }
  }

  @override
  Widget build(BuildContext context) {
    final String userRole = widget.username.toLowerCase() == 'raihan' ? 'Ketua' : 'Anggota';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Logbook Digital", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Tim: ${widget.teamId}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // FIX: UBAH TOMBOL INI UNTUK MEMBUKA LAB PCD
          IconButton(
            icon: const Icon(Icons.science), // Ikon tabung reaksi untuk Lab
            tooltip: 'Buka Laboratorium PCD',
            onPressed: () async {
              // 1. Buka kamera dan tunggu nama file kembaliannya
              final String? returnedFileName = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VisionView()),
              );

              // 2. Jika user memotret, rakit path lengkap dan buka Lab PCD
              if (returnedFileName != null && context.mounted) {
                final directory = await getApplicationDocumentsDirectory();
                final fullPath = '${directory.path}/$returnedFileName';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PcdEditorView(imagePath: fullPath),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded), 
            onPressed: _confirmLogout,
          ), 
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari judul atau deskripsi...",
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ["Semua", "Mechanical", "Electronic", "Software"].map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(color: _filterCategory == cat ? Colors.white : Colors.black87)),
                    selected: _filterCategory == cat,
                    selectedColor: Colors.indigo,
                    onSelected: (selected) => setState(() => _filterCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, currentLogs, child) {
                final filteredLogs = currentLogs.where((log) {
                  bool matchesSearch = log.title.toLowerCase().contains(_searchQuery) ||
                                       log.description.toLowerCase().contains(_searchQuery);
                  bool matchesCategory = _filterCategory == "Semua" || log.category == _filterCategory;
                  bool canSee = (log.authorId == widget.userId) || (log.isPublic == true);
                  
                  return canSee && matchesSearch && matchesCategory;
                }).toList();

                if (filteredLogs.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => _controller.loadLogs(widget.teamId),
                  color: Colors.indigo,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final bool isOwner = log.authorId == widget.userId;

                      return Dismissible(
                        key: Key(log.id ?? index.toString()),
                        direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Konfirmasi Hapus"),
                                content: const Text("Apakah Anda yakin ingin menghapus catatan ini secara permanen?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("BATAL"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) => _controller.removeLog(index, userRole, widget.userId),
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: _getHomeworkColor(log.category), width: 1),
                          ),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: log.imagePath != null
                              ? FutureBuilder<Directory>(
                                  future: getApplicationDocumentsDirectory(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final dynamicPath = File('${snapshot.data!.path}/${log.imagePath}');
                                      if (dynamicPath.existsSync()) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            dynamicPath,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                    }
                                    return CircleAvatar(
                                      backgroundColor: log.isSynced ? Colors.green.shade50 : Colors.orange.shade50,
                                      child: Icon(
                                        log.isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                                        color: log.isSynced ? Colors.green : Colors.orange,
                                        size: 24,
                                      ),
                                    );
                                  },
                                )
                              : CircleAvatar(
                                  backgroundColor: log.isSynced ? Colors.green.shade50 : Colors.orange.shade50,
                                  child: Icon(
                                    log.isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                                    color: log.isSynced ? Colors.green : Colors.orange,
                                    size: 24,
                                  ),
                                ),
                            title: Row(
                              children: [
                                Expanded(child: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                if (!log.isPublic) const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(log.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(log.category, 
                                      style: TextStyle(fontSize: 10, color: _getHomeworkColor(log.category), fontWeight: FontWeight.bold)),
                                    const Text(" • ", style: TextStyle(color: Colors.grey)),
                                    Text(_formatDateTime(log.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: isOwner ? const Icon(Icons.edit_note, color: Colors.indigo) : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LogEditorPage(
                                    log: log,
                                    index: index,
                                    controller: _controller,
                                    currentUser: {
                                      'uid': widget.userId,
                                      'teamId': widget.teamId,
                                      'username': widget.username,
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LogEditorPage(
                controller: _controller,
                currentUser: {'uid': widget.userId, 'teamId': widget.teamId, 'username': widget.username},
              ),
            ),
          );
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Catat Progress"),
      ),
    );
  }
}