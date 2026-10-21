import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../providers/suppliers_provider.dart';
import '../widgets/supplier_card.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SuppliersProvider>().suppliers;

    return Scaffold(
      appBar: AppBar(title: const Text('Fornitori')),
      body: suppliers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nessun fornitore ancora',
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
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return SupplierCard(
                  supplier: supplier,
                  onEdit: () => _showEditDialog(context, supplier),
                  onDelete: () => _confirmDelete(context, supplier),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    _showSupplierDialog(context, null);
  }

  void _showEditDialog(BuildContext context, Supplier supplier) {
    _showSupplierDialog(context, supplier);
  }

  void _showSupplierDialog(BuildContext context, Supplier? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final waCtrl = TextEditingController(text: existing?.whatsapp ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
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
                existing == null ? 'Nuovo fornitore' : 'Modifica fornitore',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Inserisci il nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: waCtrl,
                decoration:
                    const InputDecoration(labelText: 'WhatsApp * (+39...)'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
                ],
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Inserisci il numero' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration:
                    const InputDecoration(labelText: 'Email (opzionale)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final supplier = Supplier(
                      id: existing?.id,
                      name: nameCtrl.text.trim(),
                      whatsapp: waCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                    if (existing == null) {
                      await ctx.read<SuppliersProvider>().addSupplier(supplier);
                    } else {
                      await ctx
                          .read<SuppliersProvider>()
                          .updateSupplier(supplier);
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

  Future<void> _confirmDelete(BuildContext context, Supplier supplier) async {
    final hasProducts =
        await context.read<SuppliersProvider>().supplierHasProducts(supplier.id!);
    if (!context.mounted) return;
    if (hasProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non puoi eliminare un fornitore con prodotti assegnati.'),
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina fornitore'),
        content: Text('Eliminare ${supplier.name}?'),
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
      context.read<SuppliersProvider>().deleteSupplier(supplier.id!);
    }
  }
}
