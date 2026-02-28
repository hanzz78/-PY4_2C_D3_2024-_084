import 'package:flutter/material.dart';
import 'logbook_controller.dart';
import 'models/log_model.dart';
import '../auth/login_view.dart';

class LogbookView extends StatefulWidget {
  final String username;
  const LogbookView({super.key, required this.username});

  @override
  State<LogbookView> createState() => _LogbookViewState();
}
final _formKey = GlobalKey<FormState>();
class _LogbookViewState extends State<LogbookView> {
  final LogController _controller = LogController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Homework: Variabel untuk Dropdown
  String _selectedCategory = "Pribadi";
  final List<String> _categories = ["Pribadi", "Pekerjaan", "Urgent"];

  // Homework: Warna dinamis berdasarkan kategori
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

 void _showAddLogDialog() {
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text("Tambah Catatan Baru"),
        content: Form(
          key: _formKey, // Pasang kunci form di sini
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: "Judul Catatan"),
                // VALIDASI JUDUL
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(hintText: "Isi Deskripsi"),
                // VALIDASI DESKRIPSI
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi harus diisi';
                  }
                  return null;
                },
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
            onPressed: () {
              // CEK VALIDASI SEBELUM SIMPAN
              if (_formKey.currentState!.validate()) {
                _controller.addLog(
                  _titleController.text, 
                  _contentController.text, 
                  _selectedCategory
                );
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    ),
  );
}
  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    _selectedCategory = log.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Catatan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController),
              TextField(controller: _contentController),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setDialogState(() => _selectedCategory = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                _controller.updateLog(index, _titleController.text, _contentController.text, _selectedCategory);
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda yakin ingin logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginView()), (route) => false),
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
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
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _showLogoutDialog)],
      ),
      body: Column(
        children: [
          // Header Salam
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blue.shade50,
            child: Text("${_getSalam()}, ${widget.username}!", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          // Homework: Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (value) => _controller.searchLog(value),
              decoration: const InputDecoration(
                labelText: "Cari Catatan...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Homework: List Area dengan Empty State & Swipe
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, currentLogs, child) {
                // Homework: Empty State
                if (currentLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notes_rounded, size: 80, color: Colors.grey.shade300),
                        const Text("Catatan tidak ditemukan / masih kosong."),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    // Homework: Dismissible (Swipe to Delete)
                    return Dismissible(
                      key: Key(log.date),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        _controller.removeLog(index);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Catatan dihapus")));
                      },
                      child: Card(
                        color: _getCategoryColor(log.category),
                        child: ListTile(
                          leading: const Icon(Icons.note),
                          title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${log.category} - ${log.description}"),
                          onTap: () => _showEditLogDialog(index, log), // Edit saat di tap
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