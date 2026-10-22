import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/categoria.dart';
import '../providers/categorie_provider.dart';
import '../providers/products_provider.dart';
import '../theme.dart';

/// Screen for managing product categories (Gestione Categorie).
/// Supports add / edit / delete with emoji and name fields, and drag reordering.
class CategorieScreen extends StatefulWidget {
  const CategorieScreen({super.key});

  @override
  State<CategorieScreen> createState() => _CategorieScreenState();
}

class _CategorieScreenState extends State<CategorieScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategorieProvider>().loadCategories();
    });
  }

  void _showCategoryDialog(BuildContext context, {Categoria? existing}) {
    final nameCtrl = TextEditingController(text: existing?.nome ?? '');
    final emojiCtrl = TextEditingController(text: existing?.emoji ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  existing == null ? 'Nuova categoria' : 'Modifica categoria',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: emojiCtrl,
                  decoration: InputDecoration(
                    labelText: 'Emoji (opzionale)',
                    hintText: 'Es. 🥩, 🧀, 🥬, 🍷',
                    filled: true,
                    fillColor: AppTheme.bgCanvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  maxLength: 2,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nome categoria *',
                    hintText: 'Es. Carni, Latticini, Bevande',
                    filled: true,
                    fillColor: AppTheme.bgCanvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Inserisci il nome' : null,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final cat = Categoria(
                        id: existing?.id,
                        nome: nameCtrl.text.trim(),
                        emoji: emojiCtrl.text.trim().isEmpty
                            ? null
                            : emojiCtrl.text.trim(),
                      );
                      final provider = ctx.read<CategorieProvider>();
                      if (existing == null) {
                        await provider.addCategory(cat);
                      } else {
                        await provider.updateCategory(cat);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      existing == null ? 'Aggiungi categoria' : 'Salva modifiche',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Categoria categoria) async {
    final count =
        await context.read<CategorieProvider>().getProductsCount(categoria.id!);

    if (!context.mounted) return;

    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Questa categoria contiene $count prodotti. Riassegnali prima di eliminarla.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppTheme.statusWarning,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Elimina categoria',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('Sei sicuro di voler eliminare "${categoria.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annulla',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Elimina',
              style: TextStyle(
                color: AppTheme.statusDanger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<CategorieProvider>().deleteCategory(
            categoria.id!,
            onProductsChanged: () =>
                context.read<ProductsProvider>().loadProducts(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategorieProvider>();
    final categories = provider.categories;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Categorie',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppTheme.textMain,
          ),
        ),
        leading: const BackButton(color: AppTheme.textMain),
      ),
      body: categories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.category_outlined,
                          size: 38,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nessuna categoria ancora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Organizza i tuoi ingredienti per reparto (es. Carni, Latticini, Frutta e Verdura).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCategoryDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Aggiungi categoria',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final list = List<Categoria>.from(categories);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                for (int i = 0; i < list.length; i++) {
                  await provider.updateCategory(
                    list[i].copyWith(ordine: i + 1),
                  );
                }
              },
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Container(
                  key: ValueKey(cat.id),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) =>
                              _showCategoryDialog(context, existing: cat),
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          icon: Icons.edit_rounded,
                          label: 'Modifica',
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                        ),
                        SlidableAction(
                          onPressed: (_) => _confirmDelete(context, cat),
                          backgroundColor: AppTheme.statusDanger,
                          foregroundColor: Colors.white,
                          icon: Icons.delete_outline_rounded,
                          label: 'Elimina',
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(16),
                          ),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.borderSubtle),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: cat.emoji != null && cat.emoji!.isNotEmpty
                                ? Text(
                                    cat.emoji!,
                                    style: const TextStyle(fontSize: 22),
                                  )
                                : const Icon(
                                    Icons.category_rounded,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                          ),
                        ),
                        title: Text(
                          cat.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textMain,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.drag_indicator_rounded,
                          color: AppTheme.textMuted,
                        ),
                        onTap: () =>
                            _showCategoryDialog(context, existing: cat),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
