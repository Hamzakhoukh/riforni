import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/supplier.dart';
import '../theme.dart';

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppTheme.terracotta,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifica',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Elimina',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.terracotta.withAlpha(20),
            child: Text(
              supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.terracotta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            supplier.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(supplier.whatsapp),
              if (supplier.email != null && supplier.email!.isNotEmpty)
                Text(supplier.email!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          isThreeLine: supplier.email != null && supplier.email!.isNotEmpty,
          trailing: const Icon(Icons.chevron_right),
          onTap: onEdit,
        ),
      ),
    );
  }
}
