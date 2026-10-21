import '../providers/cart_provider.dart';
import '../models/supplier.dart';

class MessageBuilder {
  static String buildOrderMessage(
    Supplier supplier,
    List<CartItem> items, {
    String restaurantName = 'Riforni',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Buongiorno,');
    buffer.writeln('si prega di preparare il seguente ordine:');
    buffer.writeln();
    for (final item in items) {
      final qty = item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toString();
      buffer.writeln('${item.product.name}: $qty ${item.product.unit}');
    }
    buffer.writeln();
    buffer.write('Grazie,\n$restaurantName');
    return buffer.toString();
  }

  static Map<int, List<CartItem>> groupBySupplier(
    List<CartItem> items,
    Map<int, Supplier?> defaultSuppliers,
  ) {
    final Map<int, List<CartItem>> grouped = {};
    const int noSupplierKey = -1;
    for (final item in items) {
      final productId = item.product.id;
      final supplier = productId != null ? defaultSuppliers[productId] : null;
      final key = supplier?.id ?? noSupplierKey;
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }
}
