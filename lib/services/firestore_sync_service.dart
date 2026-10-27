import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class FirestoreSyncService {
  static const String databaseId = 'herb-db-0';
  static final FirestoreSyncService _instance = FirestoreSyncService._internal();
  factory FirestoreSyncService() => _instance;
  FirestoreSyncService._internal();

  FirebaseFirestore? _db;

  FirebaseFirestore? get db {
    try {
      _db ??= FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: databaseId,
      );
      return _db;
    } catch (e) {
      debugPrint('FirestoreSyncService: Firestore init notice: $e');
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _userProductsCollection(String userId) {
    final firestore = db;
    if (firestore == null) return null;
    return firestore.collection('users').doc(userId).collection('products');
  }

  Future<void> syncProductToCloud(String userId, Product product) async {
    try {
      final col = _userProductsCollection(userId);
      if (col == null) return;
      await col.doc(product.id).set(
        product.toJson(),
        SetOptions(merge: true),
      );
      debugPrint('✓ Synced product \${product.name} to herb-db-0');
    } catch (e) {
      debugPrint('Failed to sync product to herb-db-0: $e');
    }
  }

  Future<void> deleteProductFromCloud(String userId, String productId) async {
    try {
      final col = _userProductsCollection(userId);
      if (col == null) return;
      await col.doc(productId).delete();
      debugPrint('✓ Deleted product \$productId from herb-db-0');
    } catch (e) {
      debugPrint('Failed to delete from herb-db-0: $e');
    }
  }

  Future<List<Product>> fetchCloudProducts(String userId) async {
    try {
      final col = _userProductsCollection(userId);
      if (col == null) return [];
      final snapshot = await col.get();
      return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Failed to fetch from herb-db-0: $e');
      return [];
    }
  }
}
