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

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = context.watch<ProductsProvider>().products;
    final categories = context.watch<CategorieProvider>().categories;

    final products = allProducts.where((p) {
      final matchesQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query) ||
          (p.notes ?? '').toLowerCase().contains(_query);
      final matchesCat =
          _selectedCategoryId == null || p.categoriaId == _selectedCategoryId;
      return matchesQuery && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Prodotti',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
                color: AppTheme.textMain,
              ),
            ),
            Text(
              '${allProducts.length} ${allProducts.length == 1 ? 'prodotto a catalogo' : 'prodotti a catalogo'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showProductDialog(context, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Nuovo prodotto',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Cerca per nome, marca o note...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchCtrl.clear(),
                              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              // ── Category filter pills ──
              if (categories.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedCategoryId == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('Tutti'),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedCategoryId = null),
                            selectedColor: const Color(0xFFEFF6FF),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primary : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                            showCheckmark: false,
                          ),
                        );
                      }
                      final cat = categories[index - 1];
                      final isSelected = _selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${cat.emoji ?? '📁'} ${cat.nome}'),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _selectedCategoryId = isSelected ? null : cat.id;
                          }),
                          selectedColor: const Color(0xFFEFF6FF),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primary : const Color(0xFF475569),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 4),

              // ── List of Products or Empty State ──
              Expanded(
                child: allProducts.isEmpty
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
                                onPressed: () => _showProductDialog(context, null),
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
                    : products.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Nessun prodotto trovato',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _selectedCategoryId = null);
                                    },
                                    child: const Text('Reimposta filtri'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return _ProductTile(
                                product: product,
                                onEdit: () => _showProductDialog(context, product),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
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
  final VoidCallback onEdit;

  const _ProductTile({
    required this.product,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
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
              borderRadius: BorderRadius.circular(14),
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
            onTap: onEdit,
          ),
        ),
      ),
    );
  }
}
