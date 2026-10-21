import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/restaurant_provider.dart';
import '../utils/backup_helper.dart';
import '../utils/excel_helper.dart';
import '../theme.dart';
import 'categorie_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _logoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rp = context.read<RestaurantProvider>();
    _nameCtrl =
        TextEditingController(text: rp.name == 'Riforni' ? '' : rp.name);
    _logoPath = rp.logoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => _logoPath = file.path);
  }

  void _removeLogo() => setState(() => _logoPath = null);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context
        .read<RestaurantProvider>()
        .save(_nameCtrl.text.trim(), _logoPath);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impostazioni salvate!'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni ristorante'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo ──
              const Text('Logo ristorante',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.terracotta.withAlpha(20),
                        border: Border.all(
                            color: AppTheme.terracotta.withAlpha(60),
                            width: 2),
                      ),
                      child: _logoPath != null
                          ? ClipOval(
                              child: Image.file(
                                File(_logoPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.restaurant,
                              size: 36, color: AppTheme.terracotta),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cambia logo'),
                      ),
                      if (_logoPath != null)
                        TextButton.icon(
                          onPressed: _removeLogo,
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          label: const Text('Rimuovi logo',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // ── Name ──
              const Text('Nome del ristorante',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'es. Ristorante Da Mario',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.terracotta, width: 2),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Inserisci il nome'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Salva impostazioni'),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              // ── Backup ──
              const Text('Dati e backup',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Esporta dati'),
                onTap: () => BackupHelper.exportBackup(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Importa dati'),
                onTap: () => BackupHelper.importBackup(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
              ),
              const SizedBox(height: 24),
              // ── Categories ──
              const Text('Categorie',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Gestisci categorie'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CategorieScreen()),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
              ),
              const SizedBox(height: 24),
              // ── Excel ──
              const Text('Importa / Esporta prodotti',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Importa prodotti (Excel)'),
                onTap: () => ExcelHelper.importFromExcel(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Esporta prodotti (Excel)'),
                onTap: () => ExcelHelper.exportToExcel(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
