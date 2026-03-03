import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../services/mongo_service.dart'; 
import 'models/log_model.dart';
import '../auth/login_view.dart';

class LogbookView extends StatefulWidget {
  final String username;
  const LogbookView({super.key, required this.username});

  @override
  State<LogbookView> createState() => _LogbookViewState();
}

class _LogbookViewState extends State<LogbookView> {
  final _formKey = GlobalKey<FormState>();
  final MongoService _mongoService = MongoService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _searchQuery = ""; 
  String _selectedCategory = "Pribadi";
  final List<String> _categories = ["Pribadi", "Pekerjaan", "Urgent"];

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Pekerjaan": return Colors.orange.shade100;
      case "Urgent": return Colors.red.shade100;
      case "Pribadi": return Colors.blue.shade100;
      default: return Colors.grey.shade100;
    }
  }

  String _getSalam() {
    int hour = DateTime.now().hour;
    if (hour < 11) return "Selamat Pagi";
    if (hour < 15) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  void _refresh() => setState(() {}); 

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showAddLogDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Catatan Baru"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: "Judul Catatan"),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Judul kosong' : null,
                ),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(hintText: "Isi Deskripsi"),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Deskripsi kosong' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) => setDialogState(() => _selectedCategory = val!),
                  decoration: const InputDecoration(labelText: "Kategori"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  showDialog(
                    context: context, 
                    barrierDismissible: false, 
                    builder: (context) => const Center(child: CircularProgressIndicator())
                  );

                  try {
                    final newLog = LogModel(
                      id: mongo.ObjectId(), 
                      title: _titleController.text,
                      description: _contentController.text,
                      category: _selectedCategory,
                      date: DateTime.now().toString(),
                    );
                    
                    await _mongoService.insertLog(newLog.toMap());
                    
                    if (mounted) {
                      Navigator.pop(context); // Tutup Loading
                      Navigator.pop(context); // Tutup Dialog Form
                      _titleController.clear();
                      _contentController.clear();
                      _refresh(); 
                    }
                  } catch (e) {
                    if (mounted) Navigator.pop(context);
                    _showSnackBar("Gagal Simpan: Cek Koneksi Internet!");
                  }
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLogDialog(LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    _selectedCategory = log.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Catatan di Cloud"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Judul")),
              TextField(controller: _contentController, decoration: const InputDecoration(labelText: "Deskripsi")),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setDialogState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: "Kategori"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context, 
                  barrierDismissible: false, 
                  builder: (context) => const Center(child: CircularProgressIndicator())
                );

                try {
                  await _mongoService.updateLog(log.id, {
                    'title': _titleController.text,
                    'description': _contentController.text,
                    'category': _selectedCategory,
                  });
                  
                  if (mounted) {
                    Navigator.pop(context); // Tutup Loading
                    Navigator.pop(context); // Tutup Dialog Form
                    _titleController.clear();
                    _contentController.clear();
                    _refresh(); 
                  }
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                  _showSnackBar("Gagal Update: Cek Koneksi Internet!");
                }
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook ${widget.username}"),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()))
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blue.shade50,
            child: Text("${_getSalam()}, ${widget.username}!", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: const InputDecoration(
                labelText: "Cari Catatan di Cloud...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _mongoService.getLogs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 50, color: Colors.red),
                        const SizedBox(height: 10),
                        const Text("Gagal mengambil data: Cek Internet"),
                        ElevatedButton(onPressed: _refresh, child: const Text("Coba Lagi"))
                      ],
                    )
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Data tidak ditemukan di Atlas."));
                }

                final filteredLogs = snapshot.data!.where((log) {
                  return log.title.toLowerCase().contains(_searchQuery) || 
                         log.description.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    return Dismissible(
                      key: Key(log.id.toHexString()), 
                      direction: DismissDirection.endToStart,
                      // LOGIKA KONFIRMASI HAPUS
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Konfirmasi Hapus"),
                            content: const Text("Yakin ingin menghapus catatan ini dari Cloud?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Batal"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      onDismissed: (_) async {
                        try {
                          await _mongoService.deleteLog(log.id);
                          _showSnackBar("Catatan dihapus dari Cloud");
                        } catch (e) {
                          _showSnackBar("Gagal Hapus: Cek Internet");
                        }
                        _refresh();
                      },
                      child: Card(
                        color: _getCategoryColor(log.category),
                        child: ListTile(
                          leading: const Icon(Icons.cloud_done),
                          title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${log.category} - ${log.description}"),
                          onTap: () => _showEditLogDialog(log),
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
        backgroundColor: Colors.blue.shade400,
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}