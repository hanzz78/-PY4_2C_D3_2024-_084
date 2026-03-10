import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'models/log_model.dart';
import 'logbook_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _selectedCategory = 'Umum';
  bool _isPublic = false; // TASK 5: Default Privat
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = widget.log?.category ?? 'Umum';
    _isPublic = widget.log?.isPublic ?? false; // Load status asli
    _descController.addListener(() => setState(() {}));
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan Deskripsi tidak boleh kosong!")),
      );
      return;
    }
    
    setState(() => _isSaving = true);

    try {
      if (widget.log == null) {
        await widget.controller.addLog(
          _titleController.text, _descController.text,
          widget.currentUser['uid'], widget.currentUser['teamId'],
          category: _selectedCategory, isPublic: _isPublic,
        );
      } else {
        await widget.controller.updateLog(
          widget.index!, _titleController.text, _descController.text,
          category: _selectedCategory, isPublic: _isPublic,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah saya pemilik catatan (Sovereignty)
    final bool isOwner = widget.log == null || widget.log!.authorId == widget.currentUser['uid'];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : (isOwner ? "Edit Catatan" : "Detail Catatan")),
          bottom: const TabBar(tabs: [Tab(text: "Editor"), Tab(text: "Pratinjau")]),
          actions: [
            if (isOwner) // Hanya owner yang boleh simpan
              _isSaving 
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : IconButton(icon: const Icon(Icons.save), onPressed: _save)
          ],
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: ['Umum', 'Progress', 'Kendala', 'Rapat'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: isOwner ? (v) => setState(() => _selectedCategory = v!) : null,
                    decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Publik (Dilihat Tim)"),
                    subtitle: Text(_isPublic ? "Anggota lain bisa melihat" : "Hanya Anda yang melihat"),
                    value: _isPublic,
                    onChanged: isOwner ? (v) => setState(() => _isPublic = v) : null,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController, 
                    enabled: isOwner,
                    decoration: const InputDecoration(labelText: "Judul", border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController, 
                    maxLines: 12, enabled: isOwner,
                    decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder())
                  ),
                ],
              ),
            ),
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}