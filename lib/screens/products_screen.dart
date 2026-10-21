import 'dart:io';
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
      appBar: AppBar(title: const Text('Prodotti')),
      body: products.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nessun prodotto ancora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'aggiungine uno per iniziare',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductTile(product: product);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    _showProductDialog(context, null);
  }

  static void _showProductDialog(BuildContext context, Product? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final unitCtrl =
        TextEditingController(text: existing?.unit ?? '');
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final categories =
                ctx.watch<CategorieProvider>().categories;
            final suppliers =
                ctx.watch<SuppliersProvider>().suppliers;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existing == null
                            ? 'Nuovo prodotto'
                            : 'Modifica prodotto',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Nome *'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Inserisci il nome'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Unità (es. kg, L, pz) *'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Inserisci l\'unità'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Category dropdown
                      DropdownButtonFormField<int?>(
                        value: selectedCategoriaId,
                        decoration:
                            const InputDecoration(labelText: 'Categoria'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Nessuna categoria'),
                          ),
                          ...categories.map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(
                                    '${c.emoji ?? ''} ${c.nome}'),
                              )),
                        ],
                        onChanged: (v) =>
                            setModalState(() => selectedCategoriaId = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(labelText: 'Note'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      // Suppliers
                      if (suppliers.isNotEmpty) ...[
                        const Text(
                          'Fornitori assegnati:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        ...suppliers.map((s) => CheckboxListTile(
                              title: Text(s.name),
                              subtitle: s.id == defaultSupplierId
                                  ? const Text('Predefinito',
                                      style: TextStyle(
                                          color: AppTheme.terracotta,
                                          fontSize: 12))
                                  : null,
                              value:
                                  selectedSupplierIds.contains(s.id),
                              onChanged: (checked) {
                                setModalState(() {
                                  if (checked == true) {
                                    selectedSupplierIds.add(s.id!);
                                    defaultSupplierId ??= s.id;
                                  } else {
                                    selectedSupplierIds
                                        .remove(s.id);
                                    if (defaultSupplierId == s.id) {
                                      defaultSupplierId =
                                          selectedSupplierIds.isEmpty
                                              ? null
                                              : selectedSupplierIds
                                                  .first;
                                    }
                                  }
                                });
                              },
                              activeColor: AppTheme.terracotta,
                            )),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
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
                            final supplierLinks =
                                selectedSupplierIds.map((sid) =>
                                    ProductSupplier(
                                      productId: existing?.id ?? 0,
                                      supplierId: sid,
                                      isDefault: sid == defaultSupplierId,
                                    )).toList();
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
                          child: Text(
                              existing == null ? 'Aggiungi' : 'Salva'),
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
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) =>
                ProductsScreen._showProductDialog(context, product),
            backgroundColor: AppTheme.terracotta,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifica',
          ),
          SlidableAction(
            onPressed: (_) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Elimina prodotto'),
                  content: Text('Eliminare ${product.name}?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annulla')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Elimina',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context
                    .read<ProductsProvider>()
                    .deleteProduct(product.id!);
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Elimina',
          ),
        ],
      ),
      child: ListTile(
        leading: product.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(product.imagePath!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.terracotta.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    product.name.isNotEmpty
                        ? product.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.terracotta,
                    ),
                  ),
                ),
              ),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(product.unit),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => ProductsScreen._showProductDialog(context, product),
      ),
    );
  }
}
