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

class _LogbookViewState extends State<LogbookView> {
  final LogController _controller = LogController();

  @override
  void initState() {
    super.initState();
  }

  String _getSalam() {
    int hour = DateTime.now().hour;
    if (hour < 11) return "Selamat Pagi";
    if (hour < 15) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

final TextEditingController _titleController = TextEditingController();
final TextEditingController _contentController = TextEditingController();

void _showAddLogDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Tambah Catatan Baru"),
      content: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: "Judul Catatan"),
          ),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(hintText: "Isi Deskripsi"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () {
            _controller.addLog(
              _titleController.text, 
              _contentController.text
            );
                        
            _titleController.clear();
            _contentController.clear();
            Navigator.pop(context);
          },
          child: const Text("Simpan"),
        ),
      ],
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
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false, 
              );
            },
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
  _titleController.text = log.title;
  _contentController.text = log.description;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Edit Catatan"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _titleController),
          TextField(controller: _contentController),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            _controller.updateLog(index, _titleController.text, _contentController.text);
            _titleController.clear();
            _contentController.clear();
            Navigator.pop(context);
          },
          child: const Text("Update"),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          )
        ],
      ),
      body:  
      
      ValueListenableBuilder<List<LogModel>>(
  valueListenable: _controller.logsNotifier,
  builder: (context, currentLogs, child) {
    if (currentLogs.isEmpty) return const Center(child: Text("Belum ada catatan."));
    return ListView.builder(
      itemCount: currentLogs.length,
      itemBuilder: (context, index) {
        final log = currentLogs[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.note),
            title: Text(log.title),
            subtitle: Text(log.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), 
                  onPressed: () => _showEditLogDialog(index, log)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), 
                  onPressed: () => _controller.removeLog(index)),
              ],
            ),
          ),
        );
      },
    );
  },
),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade400,
        onPressed: () => _showAddLogDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 