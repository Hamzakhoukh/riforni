import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/history_provider.dart';
import '../providers/suppliers_provider.dart';
import '../models/order.dart';
import '../utils/whatsapp_helper.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadOrders();
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showBozzaActionSheet(BuildContext context, AppOrder order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ordine bozza — ${order.supplierName}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Questo ordine non è stato ancora confermato come inviato.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),

                // Button 1: Conferma come inviato (min 56px)
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await context.read<HistoryProvider>().updateOrderStatus(
                            order.id!,
                            AppOrder.statusInviato,
                            sentAt: DateTime.now(),
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ordine contrassegnato come inviato ✓'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Conferma come inviato', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Button 2: Reinvia con WhatsApp (min 56px)
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final supplier = context.read<SuppliersProvider>().getById(order.supplierId ?? -1);
                      if (supplier != null && WhatsappHelper.isValidE164(supplier.whatsapp)) {
                        await WhatsappHelper.sendWhatsApp(supplier.whatsapp, order.message);
                      } else {
                        await Clipboard.setData(ClipboardData(text: order.message));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Messaggio copiato negli appunti (manca numero WhatsApp)')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Reinvia con WhatsApp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Button 3: Segna come annullato
                SizedBox(
                  height: 48,
                  child: TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await context.read<HistoryProvider>().updateOrderStatus(
                            order.id!,
                            AppOrder.statusAnnullato,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ordine contrassegnato come annullato')),
                        );
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFF94A3B8)),
                    label: const Text('Segna come annullato',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final grouped = history.groupedByDate;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(title: const Text('Cronologia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20))),
      body: history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: Color(0xFF94A3B8)),
                    SizedBox(height: 16),
                    Text(
                      'Nessun ordine ancora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  for (final order in entry.value)
                    _OrderTile(
                      order: order,
                      expanded: _expanded.contains(order.id),
                      onTap: () => setState(() {
                        if (_expanded.contains(order.id)) {
                          _expanded.remove(order.id);
                        } else {
                          _expanded.add(order.id!);
                        }
                      }),
                      onManageBozza: () => _showBozzaActionSheet(context, order),
                      formatTime: _formatTime,
                    ),
                ],
              ],
            ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final AppOrder order;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onManageBozza;
  final String Function(DateTime) formatTime;

  const _OrderTile({
    required this.order,
    required this.expanded,
    required this.onTap,
    required this.onManageBozza,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Elimina ordine', style: TextStyle(fontWeight: FontWeight.w800)),
                  content: const Text(
                    'Eliminare questo ordine dalla cronologia? L\'ordine verrà nascosto dalla lista.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annulla', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Elimina', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                // Soft delete in database
                await context.read<HistoryProvider>().deleteOrder(order.id!);
              }
            },
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Elimina',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: order.isBozza ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
            width: order.isBozza ? 1.5 : 1.0,
          ),
        ),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: order.isBozza
                          ? const Color(0xFFFEF3C7)
                          : (order.isAnnullato ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF)),
                      child: Icon(
                        order.isBozza
                            ? Icons.edit_note_rounded
                            : (order.isAnnullato ? Icons.cancel_outlined : Icons.storefront_rounded),
                        size: 20,
                        color: order.isBozza
                            ? const Color(0xFFD97706)
                            : (order.isAnnullato ? const Color(0xFF94A3B8) : AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  order.supplierName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (order.isBozza)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Da confermare',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                )
                              else if (order.isAnnullato)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Annullato',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Inviato',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${order.items.length} ${order.items.length == 1 ? 'prodotto' : 'prodotti'} • ${formatTime(order.createdAt)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                if (order.isBozza) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: onManageBozza,
                      icon: const Icon(Icons.touch_app_rounded, size: 16),
                      label: const Text('Conferma o reinvia', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
                if (expanded) ...[
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                            ),
                          ),
                          Text(
                            '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
