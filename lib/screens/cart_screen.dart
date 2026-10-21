import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/restaurant_provider.dart';
import '../providers/suppliers_provider.dart';
import '../models/supplier.dart';
import '../models/product_supplier.dart';
import '../providers/products_provider.dart';
import '../utils/message_builder.dart';
import '../utils/whatsapp_helper.dart';
import '../theme.dart';
import 'dispatch_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<int, List<Supplier>> _availableSuppliers = {};
  Map<int, Supplier?> _selectedSuppliers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final productsProvider = context.read<ProductsProvider>();
    final cartItems = context.read<CartProvider>().cartItems;
    final Map<int, List<Supplier>> available = {};
    final Map<int, Supplier?> selected = {};

    for (final item in cartItems) {
      final pid = item.product.id;
      if (pid == null) continue;
      if (available.containsKey(pid)) continue;
      final suppliers = await productsProvider.getFullSuppliersForProduct(pid);
      available[pid] = suppliers;
      final defaultS = await productsProvider.getDefaultSupplier(pid);
      selected[pid] = defaultS;
    }

    if (mounted) {
      setState(() {
        _availableSuppliers = available;
        _selectedSuppliers = selected;
        _loading = false;
      });
    }
  }

  void _pickSupplierForItem(CartItem item) {
    final allSuppliers = context.read<SuppliersProvider>().suppliers;
    final pid = item.product.id;
    if (pid == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assegna fornitore a ${item.product.name}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 12),
                if (allSuppliers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nessun fornitore disponibile nel catalogo.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: allSuppliers.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (c, idx) {
                        final sup = allSuppliers[idx];
                        final hasValidWa = WhatsappHelper.isValidE164(sup.whatsapp);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(sup.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            sup.whatsapp.isNotEmpty ? sup.whatsapp : 'Nessun numero',
                            style: TextStyle(
                              color: hasValidWa ? const Color(0xFF64748B) : const Color(0xFFEF4444),
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primary),
                          onTap: () async {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedSuppliers[pid] = sup;
                            });
                            final currentSuppliers = await context.read<ProductsProvider>().getSuppliersForProduct(pid);
                            final updatedLinks = [
                              ...currentSuppliers.where((ps) => ps.supplierId != sup.id).map(
                                    (ps) => ProductSupplier(productId: pid, supplierId: ps.supplierId, isDefault: false),
                                  ),
                              ProductSupplier(productId: pid, supplierId: sup.id!, isDefault: true),
                            ];
                            if (mounted) {
                              await context.read<ProductsProvider>().updateProduct(item.product, updatedLinks);
                              await _loadSuppliers();
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showProblematicProductsDialog(List<CartItem> problematicItems) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Fornitori mancanti', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'I seguenti prodotti non possono essere ordinati perché non hanno un fornitore assegnato o il numero WhatsApp non è valido:',
                style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: problematicItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (c, i) {
                    final item = problematicItems[i];
                    final pid = item.product.id ?? 0;
                    final s = _selectedSuppliers[pid];
                    final reason = s == null
                        ? 'Nessun fornitore assegnato'
                        : (s.whatsapp.isEmpty ? 'Nessun numero WhatsApp' : 'Numero non valido (${s.whatsapp})');

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(reason, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _pickSupplierForItem(item);
                          },
                          child: const Text('Assegna', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToDispatch() async {
    final cart = context.read<CartProvider>();
    final restaurantName = context.read<RestaurantProvider>().name;
    final items = cart.cartItems;

    // Validate: any item without valid supplier or valid phone blocks "Procedi"
    final problematicItems = <CartItem>[];
    final Map<Supplier, List<CartItem>> supplierGroups = {};

    for (final item in items) {
      final pid = item.product.id ?? 0;
      final supplier = _selectedSuppliers[pid];
      if (supplier == null || !WhatsappHelper.isValidE164(supplier.whatsapp)) {
        problematicItems.add(item);
      } else {
        supplierGroups.putIfAbsent(supplier, () => []).add(item);
      }
    }

    if (problematicItems.isNotEmpty) {
      await _showProblematicProductsDialog(problematicItems);
      return;
    }

    if (supplierGroups.isEmpty || !mounted) return;

    // "Procedi" goes straight to dispatch flow without redundant summary sheet!
    final groups = supplierGroups.entries.map((e) {
      final supplier = e.key;
      final groupItems = e.value;
      final message = MessageBuilder.buildOrderMessage(
        supplier,
        groupItems,
        restaurantName: restaurantName,
      );
      return SupplierOrderGroup(
        supplier: supplier,
        items: groupItems,
        initialMessage: message,
      );
    }).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DispatchScreen(groups: groups),
      ),
    );
  }

  String _qtyLabel(double qty) => qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

  void _editQuantity(BuildContext context, CartItem item) {
    final cart = context.read<CartProvider>();
    final ctrl = TextEditingController(text: _qtyLabel(item.quantity));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text('Modifica quantità (${item.product.unit})',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 18),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'Quantità',
                    suffixText: item.product.unit,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final val = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
                      if (val != null && val > 0) {
                        cart.setQuantity(item.product, val);
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Aggiorna', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItems = cart.cartItems;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: const Text('Carrello', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: const BackButton(),
        actions: [
          if (cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      title: const Text('Svuota carrello', style: TextStyle(fontWeight: FontWeight.w800)),
                      content: const Text('Vuoi rimuovere tutti i prodotti dal carrello?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annulla', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                        TextButton(
                          onPressed: () {
                            cart.clear();
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Svuota',
                              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Svuota',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : cartItems.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    Expanded(child: _buildItemList(cart, cartItems)),
                    _buildFooter(cartItems),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 18),
          const Text(
            'Carrello vuoto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aggiungi prodotti dal catalogo per iniziare',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(CartProvider cart, List<CartItem> cartItems) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: cartItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final pid = item.product.id ?? 0;
        final availableSuppliers = _availableSuppliers[pid] ?? [];
        final selectedSupplier = _selectedSuppliers[pid];

        return _CartItemCard(
          item: item,
          selectedSupplier: selectedSupplier,
          availableSuppliers: availableSuppliers,
          onEdit: () => _editQuantity(context, item),
          onIncrement: () => cart.increment(item.product),
          onDecrement: () => cart.decrement(item.product),
          onRemove: () => cart.setQuantity(item.product, 0),
          onAssignSupplier: () => _pickSupplierForItem(item),
          onSupplierChanged: availableSuppliers.length > 1
              ? (s) => setState(() => _selectedSuppliers[pid] = s)
              : null,
        );
      },
    );
  }

  Widget _buildFooter(List<CartItem> cartItems) {
    final supplierNames = <String>{};
    int missingSupplierCount = 0;
    for (final item in cartItems) {
      final pid = item.product.id ?? 0;
      final sup = _selectedSuppliers[pid];
      if (sup == null || !WhatsappHelper.isValidE164(sup.whatsapp)) {
        missingSupplierCount++;
      } else {
        supplierNames.add(sup.name);
      }
    }
    final groupCount = supplierNames.length;
    final totalItems = cartItems.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: AppTheme.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status row
            Row(
              children: [
                _PillTag(
                  icon: Icons.inventory_2_outlined,
                  label: '$totalItems ${totalItems == 1 ? 'prodotto' : 'prodotti'}',
                ),
                const SizedBox(width: 8),
                _PillTag(
                  icon: Icons.storefront_outlined,
                  label: '$groupCount ${groupCount == 1 ? 'fornitore' : 'fornitori'}',
                ),
                if (missingSupplierCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⚠️ $missingSupplierCount da correggere',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Main CTA Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _proceedToDispatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: missingSupplierCount > 0 ? const Color(0xFFEF4444) : AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: const Color(0x402563EB),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(missingSupplierCount > 0 ? Icons.warning_amber_rounded : Icons.arrow_forward_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      missingSupplierCount > 0
                          ? 'Correggi fornitori ($missingSupplierCount)'
                          : (groupCount > 1 ? 'Prepara $groupCount ordini' : 'Invia ordine'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final Supplier? selectedSupplier;
  final List<Supplier> availableSuppliers;
  final VoidCallback onEdit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onAssignSupplier;
  final ValueChanged<Supplier?>? onSupplierChanged;

  const _CartItemCard({
    required this.item,
    required this.selectedSupplier,
    required this.availableSuppliers,
    required this.onEdit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onAssignSupplier,
    this.onSupplierChanged,
  });

  String get _qtyLabel {
    final q = item.quantity;
    return q % 1 == 0 ? q.toInt().toString() : q.toString();
  }

  bool get _hasValidPhone =>
      selectedSupplier != null && WhatsappHelper.isValidE164(selectedSupplier!.whatsapp);

  @override
  Widget build(BuildContext context) {
    final isProblematic = selectedSupplier == null || !_hasValidPhone;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isProblematic ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isProblematic ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                // Product monogram icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isProblematic ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      item.product.name.isNotEmpty ? item.product.name[0].toUpperCase() : '•',
                      style: TextStyle(
                        color: isProblematic ? const Color(0xFFEF4444) : AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and supplier / badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.3,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (selectedSupplier == null)
                        GestureDetector(
                          onTap: onAssignSupplier,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFDC2626)),
                                SizedBox(width: 4),
                                Text(
                                  'Nessun fornitore (tocca per assegnare)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (!_hasValidPhone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFDC2626)),
                              const SizedBox(width: 4),
                              Text(
                                selectedSupplier!.whatsapp.isEmpty ? 'Manca numero WhatsApp' : 'WhatsApp non valido',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          selectedSupplier!.name,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),

                // Inline Stepper
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepIconBtn(icon: Icons.remove_rounded, onTap: onDecrement),
                      GestureDetector(
                        onTap: onEdit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$_qtyLabel ${item.product.unit}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      _StepIconBtn(icon: Icons.add_rounded, onTap: onIncrement),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Delete button
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),

          // Supplier dropdown if multiple available
          if (onSupplierChanged != null && availableSuppliers.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: selectedSupplier?.id,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600),
                  items: availableSuppliers
                      .map((s) => DropdownMenuItem<int?>(
                            value: s.id,
                            child: Text('Fornitore: ${s.name}'),
                          ))
                      .toList(),
                  onChanged: (id) {
                    final s = availableSuppliers.firstWhere(
                      (s) => s.id == id,
                      orElse: () => availableSuppliers.first,
                    );
                    onSupplierChanged!(s);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 34,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: const Color(0xFF475569)),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PillTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
