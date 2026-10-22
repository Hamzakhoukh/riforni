import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/product.dart';
import '../models/product_supplier.dart';
import '../providers/products_provider.dart';
import '../providers/suppliers_provider.dart';
import '../providers/categorie_provider.dart';
import '../theme.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Prodotti',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppTheme.textMain,
          ),
        ),
        leading: const BackButton(color: AppTheme.textMain),
      ),
      body: products.isEmpty
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
                          Icons.inventory_2_outlined,
                          size: 38,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nessun prodotto ancora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aggiungi i tuoi ingredienti e articoli per gestire gli ordini ai fornitori.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddProductDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Aggiungi prodotto',
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
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductTile(product: product);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    _showProductDialog(context, null);
  }

  static void _showProductDialog(BuildContext context, Product? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    int? selectedCategoriaId = existing?.categoriaId;
    List<int> selectedSupplierIds = [];
    int? defaultSupplierId;
    final formKey = GlobalKey<FormState>();
    String? imagePath = existing?.imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final categories = ctx.watch<CategorieProvider>().categories;
            final suppliers = ctx.watch<SuppliersProvider>().suppliers;

            return Padding(
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
                        existing == null ? 'Nuovo prodotto' : 'Modifica prodotto',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nome prodotto *',
                          hintText: 'Es. Mozzarella di Bufala',
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
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Inserisci il nome'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: unitCtrl,
                        decoration: InputDecoration(
                          labelText: 'Unità di misura *',
                          hintText: 'Es. kg, L, pz, cartone',
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
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Inserisci l\'unità'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int?>(
                        value: selectedCategoriaId,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
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
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Nessuna categoria'),
                          ),
                          ...categories.map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(
                                  '${c.emoji ?? '📁'} ${c.nome}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              )),
                        ],
                        onChanged: (v) => setModalState(() => selectedCategoriaId = v),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: InputDecoration(
                          labelText: 'Note aggiuntive (opzionale)',
                          hintText: 'Es. Marca preferita, calibro',
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
                        maxLines: 2,
                      ),
                      const SizedBox(height: 18),
                      if (suppliers.isNotEmpty) ...[
                        const Text(
                          'Fornitori assegnati:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bgCanvas,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Column(
                            children: suppliers.map((s) {
                              final isSelected = selectedSupplierIds.contains(s.id);
                              final isDefault = s.id == defaultSupplierId;
                              return CheckboxListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                title: Text(
                                  s.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: isDefault
                                    ? const Text(
                                        'Fornitore predefinito',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                value: isSelected,
                                activeColor: AppTheme.primary,
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      selectedSupplierIds.add(s.id!);
                                      defaultSupplierId ??= s.id;
                                    } else {
                                      selectedSupplierIds.remove(s.id);
                                      if (defaultSupplierId == s.id) {
                                        defaultSupplierId = selectedSupplierIds.isEmpty
                                            ? null
                                            : selectedSupplierIds.first;
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final product = Product(
                              id: existing?.id,
                              name: nameCtrl.text.trim(),
                              unit: unitCtrl.text.trim(),
                              imagePath: imagePath,
                              notes: notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                              categoriaId: selectedCategoriaId,
                            );
                            final supplierLinks = selectedSupplierIds
                                .map((sid) => ProductSupplier(
                                      productId: existing?.id ?? 0,
                                      supplierId: sid,
                                      isDefault: sid == defaultSupplierId,
                                    ))
                                .toList();
                            if (existing == null) {
                              await ctx
                                  .read<ProductsProvider>()
                                  .addProduct(product, supplierLinks);
                            } else {
                              await ctx
                                  .read<ProductsProvider>()
                                  .updateProduct(product, supplierLinks);
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
                            existing == null ? 'Aggiungi prodotto' : 'Salva modifiche',
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
            );
          },
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => ProductsScreen._showProductDialog(context, product),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Modifica',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            SlidableAction(
              onPressed: (_) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      'Elimina prodotto',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    content: Text('Sei sicuro di voler eliminare "${product.name}"?'),
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
                  context.read<ProductsProvider>().deleteProduct(product.id!);
                }
              },
              backgroundColor: AppTheme.statusDanger,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              label: 'Elimina',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (!kIsWeb && product.imagePath != null && File(product.imagePath!).existsSync())
                  ? Image.file(
                      File(product.imagePath!),
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                      ),
                      child: Center(
                        child: Text(
                          product.name.isNotEmpty
                              ? product.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.textMain,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.unit,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (product.notes != null && product.notes!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
            ),
            onTap: () => ProductsScreen._showProductDialog(context, product),
          ),
        ),
      ),
    );
  }
}
