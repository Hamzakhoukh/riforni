import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../providers/cart_provider.dart';
import '../providers/history_provider.dart';
import '../providers/restaurant_provider.dart';
import '../utils/whatsapp_helper.dart';
import '../theme.dart';

class SupplierOrderGroup {
  final Supplier supplier;
  final List<CartItem> items;
  final String initialMessage;
  final int? existingOrderId;

  SupplierOrderGroup({
    required this.supplier,
    required this.items,
    required this.initialMessage,
    this.existingOrderId,
  });
}

enum SupplierOrderStatus {
  inviato,
  daConfermare,
  saltato,
}

class SupplierOrderResult {
  final Supplier supplier;
  final int itemCount;
  final SupplierOrderStatus status;
  final int? orderId;

  SupplierOrderResult({
    required this.supplier,
    required this.itemCount,
    required this.status,
    this.orderId,
  });
}

class DispatchScreen extends StatefulWidget {
  final List<SupplierOrderGroup> groups;

  DispatchScreen({
    super.key,
    List<SupplierOrderGroup>? groups,
    Supplier? supplier,
    List<CartItem>? items,
    String? initialMessage,
    bool isLast = true,
    int? existingOrderId,
  }) : groups = groups ??
            [
              if (supplier != null)
                SupplierOrderGroup(
                  supplier: supplier,
                  items: items ?? [],
                  initialMessage: initialMessage ?? '',
                  existingOrderId: existingOrderId,
                )
            ];

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late TextEditingController _msgCtrl;
  bool _messageExpanded = false;

  bool _sending = false;
  bool _waitingConfirmation = false;
  bool _inlineConfirmationMode = false;
  int? _currentOrderId;

  final List<SupplierOrderResult> _results = [];
  bool _isFinalSummary = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCurrentSupplier();
  }

  void _initCurrentSupplier() {
    _msgCtrl = TextEditingController(text: _currentGroup.initialMessage);
    _currentOrderId = _currentGroup.existingOrderId;
    _messageExpanded = false;
    _sending = false;
    _waitingConfirmation = false;
    _inlineConfirmationMode = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingConfirmation && mounted) {
      setState(() {
        _waitingConfirmation = false;
        _inlineConfirmationMode = true;
      });
    }
  }

  SupplierOrderGroup get _currentGroup => widget.groups[_currentIndex];
  int get _totalGroups => widget.groups.length;
  String get _supplierName => _currentGroup.supplier.name;
  bool get _hasValidWhatsapp => WhatsappHelper.isValidE164(_currentGroup.supplier.whatsapp);
  bool get _hasEmail => _currentGroup.supplier.email?.isNotEmpty == true;

  Future<int> _ensureBozzaSaved(String message) async {
    if (_currentOrderId != null) return _currentOrderId!;
    final historyProvider = context.read<HistoryProvider>();
    final orderItems = _currentGroup.items
        .map((ci) => OrderItem(
              productName: ci.product.name,
              quantity: ci.quantity,
              unit: ci.product.unit,
            ))
        .toList();
    final newId = await historyProvider.saveOrder(AppOrder(
      createdAt: DateTime.now(),
      supplierId: _currentGroup.supplier.id,
      supplierName: _supplierName,
      message: message,
      items: orderItems,
      status: AppOrder.statusBozza,
    ));
    _currentOrderId = newId;
    return newId;
  }

  Future<void> _onSendWhatsapp() async {
    if (_sending) return;
    if (!_hasValidWhatsapp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numero WhatsApp non valido. Richiesto formato internazionale (es. +393331234567).'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    final message = _msgCtrl.text.trim();

    // 1. Save as BOZZA in database
    await _ensureBozzaSaved(message);

    // 2. Launch WhatsApp
    final launched = await WhatsappHelper.sendWhatsApp(_currentGroup.supplier.whatsapp, message);

    if (!mounted) return;
    setState(() => _sending = false);

    if (launched) {
      _waitingConfirmation = true;
    } else {
      _showWhatsAppFailureDialog(message);
    }
  }

  Future<void> _onConfirmSent() async {
    if (_currentOrderId != null) {
      await context.read<HistoryProvider>().updateOrderStatus(
            _currentOrderId!,
            AppOrder.statusInviato,
            sentAt: DateTime.now(),
          );
    }

    // Remove confirmed items from CartProvider
    final cart = context.read<CartProvider>();
    for (final ci in _currentGroup.items) {
      cart.setQuantity(ci.product, 0);
    }

    _results.add(SupplierOrderResult(
      supplier: _currentGroup.supplier,
      itemCount: _currentGroup.items.length,
      status: SupplierOrderStatus.inviato,
      orderId: _currentOrderId,
    ));

    _advanceToNextSupplier();
  }

  void _onNotSentYet() {
    // Order remains bozza in database, items remain in cart
    _results.add(SupplierOrderResult(
      supplier: _currentGroup.supplier,
      itemCount: _currentGroup.items.length,
      status: SupplierOrderStatus.daConfermare,
      orderId: _currentOrderId,
    ));

    _advanceToNextSupplier();
  }

  Future<void> _onRetryWhatsApp() async {
    setState(() {
      _inlineConfirmationMode = false;
      _waitingConfirmation = true;
    });
    final message = _msgCtrl.text.trim();
    final launched = await WhatsappHelper.sendWhatsApp(_currentGroup.supplier.whatsapp, message);
    if (!launched && mounted) {
      setState(() {
        _waitingConfirmation = false;
      });
      _showWhatsAppFailureDialog(message);
    }
  }

  void _onSkipSupplier() {
    // Order stays in the cart, NO bozza created in database
    _results.add(SupplierOrderResult(
      supplier: _currentGroup.supplier,
      itemCount: _currentGroup.items.length,
      status: SupplierOrderStatus.saltato,
    ));

    _advanceToNextSupplier();
  }

  void _advanceToNextSupplier() {
    if (_currentIndex < _totalGroups - 1) {
      setState(() {
        _currentIndex++;
        _msgCtrl.dispose();
        _initCurrentSupplier();
      });
    } else {
      setState(() {
        _isFinalSummary = true;
      });
    }
  }

  void _showWhatsAppFailureDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEAB308), size: 26),
            SizedBox(width: 8),
            Text('WhatsApp non disponibile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Impossibile avviare WhatsApp sul dispositivo. Puoi copiare il messaggio o inviarlo via email (l\'ordine rimane salvato come bozza):',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Messaggio copiato negli appunti'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copia messaggio'),
          ),
          if (_hasEmail)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await WhatsappHelper.sendEmail(
                  email: _currentGroup.supplier.email!,
                  subject: 'Ordine da ${context.read<RestaurantProvider>().name}',
                  body: message,
                );
              },
              icon: const Icon(Icons.mail_outline_rounded, size: 16),
              label: const Text('Invia via email'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinalSummary) return _buildFinalSummary();

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: Text(
          _supplierName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header: "Fornitore X di N" + thin progress bar (hidden if N == 1)
            if (_totalGroups > 1) _buildMultiHeader(),

            // Main scrollable content (avoids any overflow on 360x640)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSupplierCard(),
                    _buildCollapsedMessagePreview(),
                  ],
                ),
              ),
            ),

            // Bottom action area (fixed at bottom, safe from overflow)
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fornitore ${_currentIndex + 1} di $_totalGroups',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
              if (_currentIndex < _totalGroups - 1)
                Text(
                  'Prossimo: ${widget.groups[_currentIndex + 1].supplier.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _totalGroups,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _supplierName.isNotEmpty ? _supplierName[0].toUpperCase() : '•',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _supplierName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentGroup.supplier.whatsapp,
                  style: TextStyle(
                    fontSize: 13,
                    color: _hasValidWhatsapp ? const Color(0xFF64748B) : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_currentGroup.items.length} ${_currentGroup.items.length == 1 ? 'voce' : 'voci'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedMessagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _messageExpanded = !_messageExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Messaggio WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  const Spacer(),
                  Text(
                    _messageExpanded ? 'Comprimi' : 'Tocca per modificare',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _messageExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (!_messageExpanded)
            InkWell(
              onTap: () => setState(() => _messageExpanded = true),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _msgCtrl.text.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'monospace',
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 7,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'monospace',
                  color: Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // INLINE CONFIRMATION STATE (replaces the modal sheet!)
          if (_inlineConfirmationMode) ...[
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onConfirmSent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 22),
                    SizedBox(width: 8),
                    Text('Sì, inviato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _onNotSentYet,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Non ancora', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _onRetryWhatsApp,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Riprova', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // DEFAULT STATE: ONE primary button "Invia con WhatsApp"
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_sending || !_hasValidWhatsapp) ? null : _onSendWhatsapp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Invia con WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 6),

            // Secondary row: Copia + Email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final message = _msgCtrl.text.trim();
                    await _ensureBozzaSaved(message);
                    await Clipboard.setData(ClipboardData(text: message));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Messaggio copiato — confermalo dopo averlo inviato'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      setState(() => _inlineConfirmationMode = true);
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF64748B)),
                  label: const Text('Copia testo', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (_hasEmail) ...[
                  const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                  TextButton.icon(
                    onPressed: () async {
                      final message = _msgCtrl.text.trim();
                      await _ensureBozzaSaved(message);
                      await WhatsappHelper.sendEmail(
                        email: _currentGroup.supplier.email!,
                        subject: 'Ordine da ${context.read<RestaurantProvider>().name}',
                        body: message,
                      );
                      if (mounted) {
                        // Same lifecycle pattern as WhatsApp: on resume → show confirmation
                        setState(() => _waitingConfirmation = true);
                      }
                    },
                    icon: const Icon(Icons.mail_outline_rounded, size: 15, color: Color(0xFF64748B)),
                    label: const Text('Invia email', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),

            // Skip button: "Salta questo fornitore"
            TextButton(
              onPressed: _onSkipSupplier,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Salta questo fornitore',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinalSummary() {
    final allInviati = _results.isNotEmpty && _results.every((r) => r.status == SupplierOrderStatus.inviato);

    final iconColor = allInviati ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final iconBg = allInviati ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final headerIcon = allInviati ? Icons.check_circle_rounded : Icons.assignment_turned_in_outlined;
    final headerTitle = allInviati ? 'Tutti gli ordini inviati!' : 'Riepilogo invio ordini';
    final headerSubtitle = allInviati
        ? '${_results.length} ordini confermati e rimossi dal carrello'
        : 'Verifica lo stato degli ordini prima di concludere';

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: const Text('Riepilogo finale', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                      child: Icon(headerIcon, color: iconColor, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      headerTitle,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headerSubtitle,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // List of suppliers with check/warning/skip
                    for (final r in _results) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: r.status == SupplierOrderStatus.daConfermare
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  r.supplier.name.isNotEmpty ? r.supplier.name[0].toUpperCase() : '•',
                                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.supplier.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.itemCount} ${r.itemCount == 1 ? 'prodotto' : 'prodotti'}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            if (r.status == SupplierOrderStatus.inviato)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                    SizedBox(width: 4),
                                    Text('Inviato', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                                  ],
                                ),
                              )
                            else if (r.status == SupplierOrderStatus.daConfermare)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                                    SizedBox(width: 4),
                                    Text('Da confermare', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Nel carrello', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom CTA: "Torna alla home"
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Torna alla home', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
