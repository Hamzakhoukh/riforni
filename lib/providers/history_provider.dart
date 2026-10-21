import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/order.dart';

class HistoryProvider extends ChangeNotifier {
  List<AppOrder> _orders = [];

  List<AppOrder> get orders => _orders;
  bool get isEmpty => _orders.isEmpty;

  Future<void> loadOrders() async {
    _orders = await DatabaseHelper.instance.getAllOrders();
    notifyListeners();
  }

  Future<int> saveOrder(AppOrder order) async {
    final id = await DatabaseHelper.instance.insertOrder(order);
    await loadOrders();
    return id;
  }

  Future<void> updateOrderStatus(int id, String status, {DateTime? sentAt}) async {
    await DatabaseHelper.instance.updateOrderStatus(id, status, sentAt: sentAt);
    await loadOrders();
  }

  Future<void> deleteOrder(int id) async {
    await DatabaseHelper.instance.deleteOrder(id);
    await loadOrders();
  }

  /// Groups orders by date: 'Oggi', 'Ieri', or Italian date string.
  Map<String, List<AppOrder>> get groupedByDate {
    final Map<String, List<AppOrder>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final order in _orders) {
      final d = order.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      String label;
      if (day == today) {
        label = 'Oggi';
      } else if (day == yesterday) {
        label = 'Ieri';
      } else {
        const months = [
          '', 'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
          'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
        ];
        label = '${d.day} ${months[d.month]} ${d.year}';
      }
      grouped.putIfAbsent(label, () => []).add(order);
    }
    return grouped;
  }
}
