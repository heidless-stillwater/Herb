import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_sync_service.dart';

enum SubscriptionPlanTier {
  free,
  standard,
  pro;

  static SubscriptionPlanTier fromId(String? val) {
    if (val == null) return SubscriptionPlanTier.free;
    switch (val.toLowerCase()) {
      case 'pro':
      case 'sovereign':
      case 'enterprise':
        return SubscriptionPlanTier.pro;
      case 'standard':
        return SubscriptionPlanTier.standard;
      default:
        return SubscriptionPlanTier.free;
    }
  }

  double get priceMonthlyGbp {
    switch (this) {
      case SubscriptionPlanTier.free:
        return 0.0;
      case SubscriptionPlanTier.standard:
        return 9.99;
      case SubscriptionPlanTier.pro:
        return 29.99;
    }
  }

  bool get isSubscribed => this != SubscriptionPlanTier.free;
}

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  SubscriptionPlanTier _tier = SubscriptionPlanTier.free;
  SubscriptionPlanTier get tier => _tier;
  bool get isSubscribed => _tier != SubscriptionPlanTier.free;
  bool get isPro => _tier == SubscriptionPlanTier.pro;

  static const String _prefKey = 'herb_subscription_tier_cache';

  Future<void> initFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        _tier = SubscriptionPlanTier.fromId(saved);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Syncs and verifies subscription status from Firestore (herb-db-0)
  Future<SubscriptionPlanTier> fetchSubscriptionStatus(
    String userId, {
    bool isSuperUser = false,
  }) async {
    if (isSuperUser) {
      _tier = SubscriptionPlanTier.pro;
      await _cacheLocally(_tier);
      notifyListeners();
      return _tier;
    }

    try {
      final db = FirestoreSyncService().db;
      if (db == null) return _tier;

      final doc = await db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        final rawTier = data?['subscriptionType'] ??
            data?['subscription']?['tier'] ??
            data?['tier'];
        if (rawTier != null) {
          _tier = SubscriptionPlanTier.fromId(rawTier.toString());
          await _cacheLocally(_tier);
          notifyListeners();
          return _tier;
        }
      }
    } catch (e) {
      debugPrint('Subscription fetch notice: $e');
    }
    return _tier;
  }

  /// Activates or upgrades plan locally and syncs to herb-db-0
  Future<void> activatePlan(
    String userId,
    SubscriptionPlanTier newTier, {
    String? paymentMethod,
  }) async {
    _tier = newTier;
    await _cacheLocally(newTier);
    notifyListeners();

    try {
      final db = FirestoreSyncService().db;
      if (db == null) return;

      final tierString = newTier == SubscriptionPlanTier.pro
          ? 'pro'
          : newTier == SubscriptionPlanTier.standard
              ? 'standard'
              : 'free';

      await db.collection('users').doc(userId).set({
        'subscriptionType': tierString,
        'subscription': {
          'tier': tierString,
          'status': 'active',
          'activeSuites': ['herb', 'resources', 'studio', 'registry'],
          'paymentMethod': paymentMethod ?? 'stripe_mobile',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✓ Activated $tierString subscription for user $userId on herb-db-0');
    } catch (e) {
      debugPrint('Failed to sync activated plan to Firestore: $e');
    }
  }

  Future<void> _cacheLocally(SubscriptionPlanTier tier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, tier.name);
    } catch (_) {}
  }
}
