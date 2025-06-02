import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseServiceShoppingList {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference getShoppingListCollectionForUser(String uid) {
    return _firestore.collection('users').doc(uid).collection('shoppingList');
  }

  Future<List<Map<String, dynamic>>> getShoppingList(String uid) async {
    final snapshot = await getShoppingListCollectionForUser(uid).get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> addItem(String uid, String name, String quantity, String unit) async {
    final collection = getShoppingListCollectionForUser(uid);
    await collection.add({
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'bought': false,
    });
  }

  Future<void> addIngredients(String uid, List<List<String>> ingredients) async {
    final collection = getShoppingListCollectionForUser(uid);
    // Fetch current shopping list to avoid duplicates
    final currentItems = await getShoppingList(uid);
    final currentNames = currentItems.map((e) => (e['name'] ?? '').toString().toLowerCase()).toSet();
    final batch = _firestore.batch();
    for (final ingredient in ingredients) {
      final name = ingredient.isNotEmpty ? ingredient[0] : '';
      final nameKey = name.toLowerCase();
      if (nameKey.isEmpty || currentNames.contains(nameKey)) continue;
      batch.set(collection.doc(), {
        'name': name,
        'quantity': '', // Do not add amount from recipe
        'unit': '',
        'bought': false,
      });
      currentNames.add(nameKey); // Prevent adding same ingredient twice in this batch
    }
    await batch.commit();
  }

  Future<void> updateItemBought(String uid, String name, bool bought) async {
    final collection = getShoppingListCollectionForUser(uid);
    final query = await collection.where('name', isEqualTo: name).get();
    for (final doc in query.docs) {
      await doc.reference.update({'bought': bought});
    }
  }

  Future<void> removeItem(String uid, String name) async {
    final collection = getShoppingListCollectionForUser(uid);
    final query = await collection.where('name', isEqualTo: name).get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }
}
