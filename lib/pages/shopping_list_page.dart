import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:BiteBudget/services/database_service_shopping_list.dart';
import 'package:intl/intl.dart';

class ShoppingListPage extends StatefulWidget {
  static final ValueNotifier<int> shoppingListUpdateNotifier = ValueNotifier<int>(0);
  const ShoppingListPage({Key? key}) : super(key: key);

  static Future<void> addIngredientsToShoppingList(String userId, List<List<String>> ingredients) async {
    final db = DatabaseServiceShoppingList();
    await db.addIngredients(userId, ingredients);
    shoppingListUpdateNotifier.value++;
  }

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  bool _loading = true;
  List<_ShoppingItem> _items = [];
  late final VoidCallback _shoppingListUpdateListener;

  @override
  void initState() {
    super.initState();
    _shoppingListUpdateListener = () => _loadShoppingList();
    ShoppingListPage.shoppingListUpdateNotifier.addListener(_shoppingListUpdateListener);
    _loadShoppingList();
  }

  @override
  void dispose() {
    ShoppingListPage.shoppingListUpdateNotifier.removeListener(_shoppingListUpdateListener);
    super.dispose();
  }

  Future<void> _loadShoppingList() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final db = DatabaseServiceShoppingList();
    final items = await db.getShoppingList(user.uid);
    setState(() {
      _items = items.map((e) => _ShoppingItem(
        name: e['name'] ?? '',
        quantity: e['quantity'] ?? '',
        unit: e['unit'] ?? '',
        bought: e['bought'] ?? false,
      )).toList();
      _loading = false;
    });
  }

  void _toggleBought(_ShoppingItem item) {
    setState(() {
      item.bought = !item.bought;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final db = DatabaseServiceShoppingList();
      db.updateItemBought(user.uid, item.name, item.bought);
    }
  }

  void _removeItem(_ShoppingItem item) {
    setState(() {
      _items.remove(item);
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final db = DatabaseServiceShoppingList();
      db.removeItem(user.uid, item.name);
    }
  }

  void _showAddItemDialog() {
    String name = '';
    String quantity = '';
    String unit = '';
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Item name', labelStyle: TextStyle(color: Colors.black54)),
                style: const TextStyle(color: Colors.black),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Quantity', labelStyle: TextStyle(color: Colors.black54)),
                      style: const TextStyle(color: Colors.black),
                      onChanged: (v) => quantity = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Unit', labelStyle: TextStyle(color: Colors.black54)),
                      style: const TextStyle(color: Colors.black),
                      onChanged: (v) => unit = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (name.trim().isNotEmpty) {
                      setState(() {
                        _items.add(_ShoppingItem(name: name.trim(), quantity: quantity.trim(), unit: unit.trim()));
                      });
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final db = DatabaseServiceShoppingList();
                        await db.addItem(user.uid, name.trim(), quantity.trim(), unit.trim());
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    // For DateFormat, ensure you have intl in your pubspec.yaml:
    // dependencies:
    //   intl: ^0.19.0
    final dateRange = '${monday.day}-${sunday.day} ${DateFormat('MMM').format(sunday)}';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: null, // Remove the AppBar title
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restore the black title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text('Shopping List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                child: Text(dateRange, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? const Center(child: Text('No shopping list for this week.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final item = _items[idx];
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: item.bought ? 0.5 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F8F8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE6E6E6)),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: item.bought,
                                        onChanged: (_) => _toggleBought(item),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        activeColor: Colors.black,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                  decoration: item.bought ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                              if (item.quantity.isNotEmpty || item.unit.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text(
                                                    '${item.quantity} ${item.unit}'.trim(),
                                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFBDBDBD)),
                                        onPressed: () => _removeItem(item),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 20),
                    label: const Text(
                      'Add new Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Inter',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      elevation: 2,
                      shadowColor: Colors.black26,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Inter',
                      ),
                    ),
                    onPressed: _showAddItemDialog,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShoppingItem {
  final String name;
  final String quantity;
  final String unit;
  bool bought;
  _ShoppingItem({required this.name, this.quantity = '', this.unit = '', this.bought = false});
}
