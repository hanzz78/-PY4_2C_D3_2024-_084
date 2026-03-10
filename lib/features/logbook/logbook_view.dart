import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'logbook_controller.dart'; 
import 'log_editor_page.dart'; 
import 'models/log_model.dart';
import '../auth/login_view.dart';
import '../../services/access_control_service.dart';

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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Progress': return Colors.blue;
      case 'Kendala': return Colors.red;
      case 'Rapat': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(count.toString(), 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
            ],
          ),
        ),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.loadLogs(widget.teamId)),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _confirmLogout), 
        ],
      ),
      body: Column(
        children: [
          // 1. STATISTIK (Sesuai Task 5: Hanya menghitung yang boleh dilihat)
          ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.logsNotifier,
            builder: (context, logs, _) {
              final visibleLogs = logs.where((l) => (l.authorId == widget.userId) || (l.isPublic == true));
              int progress = visibleLogs.where((l) => l.category == 'Progress').length;
              int kendala = visibleLogs.where((l) => l.category == 'Kendala').length;
              int rapat = visibleLogs.where((l) => l.category == 'Rapat').length;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _buildStatCard("Progress", progress, Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard("Kendala", kendala, Colors.red),
                    const SizedBox(width: 8),
                    _buildStatCard("Rapat", rapat, Colors.orange),
                  ],
                ),
              );
            },
          ),

          // 2. SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari judul...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),

          // 3. FILTER CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ["Semua", "Progress", "Kendala", "Rapat", "Umum"].map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _filterCategory == cat,
                    onSelected: (selected) => setState(() => _filterCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),

          // 4. LIST (TASK 5 HOTS LOGIC)
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, currentLogs, child) {
                final filteredLogs = currentLogs.where((log) {
                  // HINT 2: VISIBILITY LOGIC (Saya adalah Pemilik ATAU Catatan Publik)
                  bool canSee = (log.authorId == widget.userId) || (log.isPublic == true);

                  bool matchesSearch = log.title.toLowerCase().contains(_searchQuery);
                  bool matchesCategory = _filterCategory == "Semua" || log.category == _filterCategory;
                  
                  return canSee && matchesSearch && matchesCategory;
                }).toList();

                if (filteredLogs.isEmpty) {
                  return const Center(child: Text("Data Kosong atau Tidak Ditemukan"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final bool isOwner = log.authorId == widget.userId;
                    
                    // HINT 3: SOVEREIGNTY (Hanya pemilik yang boleh edit/hapus)
                    bool canAction = isOwner; 

                    return Dismissible(
                      key: Key(log.id ?? index.toString()),
                      // Matikan swipe jika bukan owner
                      direction: canAction ? DismissDirection.endToStart : DismissDirection.none,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Hapus Catatan"),
                            content: const Text("Hapus permanen data milik Anda?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context, true), 
                                child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: log.isSynced ? Colors.green.shade50 : Colors.orange.shade50,
                            child: Icon(
                              log.isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                              color: log.isSynced ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                              if (!log.isPublic) const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(log.category).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(log.category, style: TextStyle(fontSize: 10, color: _getCategoryColor(log.category), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(log.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_formatDateTime(log.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          // HINT UI: Tombol edit muncul HANYA jika isOwner == true
                          trailing: canAction ? const Icon(Icons.edit_note, color: Colors.indigo) : null,
                          onTap: () {
                            // Anggota lain/Ketua tetap bisa klik untuk LIHAT (View Only di Editor)
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
    );
  }
}