import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/categoria.dart';
import '../providers/categorie_provider.dart';
import '../providers/products_provider.dart';
import '../theme.dart';

/// Screen for managing product categories (Gestione Categorie).
/// Supports add / edit / delete with emoji and name fields.
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Nuova categoria' : 'Modifica categoria',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emojiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Emoji (opzionale)',
                  hintText: '🍕',
                  border: OutlineInputBorder(),
                ),
                maxLength: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome categoria *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Inserisci il nome' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
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
                  child: Text(existing == null ? 'Aggiungi' : 'Salva'),
                ),
              ),
            ],
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
              'Questa categoria ha $count prodotti. Riassegnali prima di eliminarla.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina categoria'),
        content: Text('Eliminare "${categoria.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Elimina', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(title: const Text('Categorie')),
      body: categories.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nessuna categoria ancora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) async {
                // Reorder locally then persist
                if (newIndex > oldIndex) newIndex--;
                final list = List<Categoria>.from(categories);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                for (int i = 0; i < list.length; i++) {
                  await provider.updateCategory(
                      list[i].copyWith(ordine: i + 1));
                }
              },
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Slidable(
                  key: ValueKey(cat.id),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) =>
                            _showCategoryDialog(context, existing: cat),
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Modifica',
                      ),
                      SlidableAction(
                        onPressed: (_) => _confirmDelete(context, cat),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Elimina',
                      ),
                    ],
                  ),
                  child: Card(
                    key: ValueKey('card_${cat.id}'),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: cat.emoji != null
                          ? Text(cat.emoji!,
                              style: const TextStyle(fontSize: 28))
                          : CircleAvatar(
                              backgroundColor:
                                  AppTheme.primary.withAlpha(20),
                              child: const Icon(Icons.category,
                                  color: AppTheme.primary, size: 20),
                            ),
                      title: Text(
                        cat.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.drag_handle,
                          color: Colors.grey),
                      onTap: () =>
                          _showCategoryDialog(context, existing: cat),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
