import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/restaurant_provider.dart';
import '../utils/backup_helper.dart';
import '../theme.dart';
import 'categorie_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  String? _logoPath;
  bool _saving = false;
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    final rp = context.read<RestaurantProvider>();
    _nameCtrl.text = rp.name == 'Riforni' ? '' : rp.name;
    _logoPath = rp.logoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => _logoPath = file.path);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await context.read<RestaurantProvider>().save(name, _logoPath);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editingName = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Salvato ✓'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.statusSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RestaurantProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Impostazioni',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        leading: const BackButton(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [

              // ── Profilo ristorante ──
              _sectionLabel('Ristorante'),
              _buildProfileCard(rp),
              const SizedBox(height: 28),

              // ── Catalogo ──
              _sectionLabel('Catalogo'),
              _buildCard([
                _tile(
                  icon: Icons.category_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  iconBg: const Color(0xFFF3E8FF),
                  title: 'Gestisci categorie',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategorieScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 28),

              // ── Dati & Backup ──
              _sectionLabel('Dati e backup'),
              _buildCard([
                _tile(
                  icon: Icons.upload_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  title: 'Esporta backup',
                  onTap: () => BackupHelper.exportBackup(context),
                ),
                _divider(),
                _tile(
                  icon: Icons.download_rounded,
                  iconColor: const Color(0xFF0891B2),
                  iconBg: const Color(0xFFCFFAFE),
                  title: 'Importa backup',
                  onTap: () => BackupHelper.importBackup(context),
                ),
              ]),
              const SizedBox(height: 28),

              // ── Info app ──
              _sectionLabel('Informazioni'),
              _buildCard([
                _tile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF64748B),
                  iconBg: const Color(0xFFF1F5F9),
                  title: 'Riforni',
                  subtitle: 'Versione 1.0.0 — Gestione ordini fornitore',
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Profile card ────────────────────────────────────────────────────────
  Widget _buildProfileCard(RestaurantProvider rp) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Avatar con pulsante camera
          GestureDetector(
            onTap: _pickLogo,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withAlpha(18),
                    border: Border.all(
                        color: AppTheme.primary.withAlpha(40), width: 2),
                  ),
                  child: _logoPath != null
                      ? ClipOval(
                          child: Image.file(File(_logoPath!), fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            rp.name.isNotEmpty
                                ? rp.name[0].toUpperCase()
                                : 'R',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nome — visualizza o modifica
          if (!_editingName)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    rp.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _editingName = true),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.borderMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 14, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                    decoration: InputDecoration(
                      hintText: 'es. Ristorante Da Mario',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _saving
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded,
                            color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),

          // Rimuovi logo
          if (_logoPath != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                setState(() => _logoPath = null);
                await context.read<RestaurantProvider>().removeLogo();
              },
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 15, color: AppTheme.statusDanger),
              label: const Text(
                'Rimuovi foto',
                style: TextStyle(
                    color: AppTheme.statusDanger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              style:
                  TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      );

  Widget _buildCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _divider() => const Divider(
      height: 1, indent: 56, endIndent: 0, color: AppTheme.borderMuted);

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textMain),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
