import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mana_poster/app/config/subscription_plan_config.dart';

class PurchaseInvoiceService {
  PurchaseInvoiceService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<List<PurchaseInvoice>> fetchInvoices({int limit = 50}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const <PurchaseInvoice>[];
    }

    final safeLimit = limit.clamp(1, 100);
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchaseEvents')
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .get();

    return snapshot.docs
        .map((doc) => PurchaseInvoice.fromFirestore(doc.id, doc.data()))
        .where((invoice) => invoice.isDisplayable)
        .toList(growable: false);
  }
}

class PurchaseInvoice {
  const PurchaseInvoice({
    required this.id,
    required this.type,
    required this.planName,
    required this.priceLabel,
    required this.statusLabel,
    required this.createdAt,
    required this.transactionAt,
    required this.expiryAt,
    required this.orderId,
    required this.platform,
  });

  final String id;
  final String type;
  final String planName;
  final String priceLabel;
  final String statusLabel;
  final DateTime? createdAt;
  final DateTime? transactionAt;
  final DateTime? expiryAt;
  final String? orderId;
  final String? platform;

  bool get isDisplayable => planName.trim().isNotEmpty;

  DateTime? get displayDate => transactionAt ?? createdAt;

  factory PurchaseInvoice.fromFirestore(String id, Map<String, dynamic> data) {
    final type = _readString(data['type']);
    final productId = _readString(data['productId']);
    final basePlanId = _readString(data['basePlanId']);
    final templateId = _readString(data['templateId']);
    final status = _statusLabel(data);
    final plan = _planLabel(
      type: type,
      productId: productId,
      basePlanId: basePlanId,
      templateId: templateId,
    );

    return PurchaseInvoice(
      id: id,
      type: type,
      planName: plan.name,
      priceLabel: plan.price,
      statusLabel: status,
      createdAt: _readDate(data['createdAt']),
      transactionAt: _readDate(data['transactionDate']),
      expiryAt: _readDate(data['expiryTime']),
      orderId: _maskOrderId(
        _readString(data['latestOrderId']).isNotEmpty
            ? _readString(data['latestOrderId'])
            : _readString(data['transactionId']),
      ),
      platform: _readString(data['platform']),
    );
  }

  static _PurchaseInvoicePlan _planLabel({
    required String type,
    required String productId,
    required String basePlanId,
    required String templateId,
  }) {
    final normalizedProduct = productId.toLowerCase();
    final normalizedBasePlan = basePlanId.toLowerCase();
    if (normalizedProduct ==
        SubscriptionPlanConfig.primaryMonthlyProductId.toLowerCase()) {
      return const _PurchaseInvoicePlan(
        name: 'Mana Poster Premium',
        price: 'Rs.149 monthly',
      );
    }
    if (normalizedProduct ==
        EditorSubscriptionPlanConfig.productId.toLowerCase()) {
      if (normalizedBasePlan == EditorSubscriptionPlanConfig.yearlyBasePlanId) {
        return const _PurchaseInvoicePlan(
          name: 'Editor Pro',
          price: 'Rs.699 yearly',
        );
      }
      return const _PurchaseInvoicePlan(
        name: 'Editor Pro',
        price: 'Rs.99 monthly',
      );
    }
    if (type == 'template_verify' || templateId.isNotEmpty) {
      return _PurchaseInvoicePlan(
        name: templateId.isEmpty ? 'Premium template' : 'Template $templateId',
        price: 'Google Play purchase',
      );
    }
    if (productId.isNotEmpty) {
      return _PurchaseInvoicePlan(
        name: productId.replaceAll('_', ' '),
        price: 'Google Play purchase',
      );
    }
    return const _PurchaseInvoicePlan(
      name: 'Google Play purchase',
      price: 'Google Play purchase',
    );
  }

  static String _statusLabel(Map<String, dynamic> data) {
    final purchaseStatus = _readString(data['purchaseStatus']);
    if (purchaseStatus.isNotEmpty) {
      return purchaseStatus;
    }
    final subscriptionState = _readString(data['subscriptionState']);
    if (subscriptionState.isNotEmpty) {
      return subscriptionState;
    }
    final status = _readString(data['status']);
    if (status.isNotEmpty) {
      return status;
    }
    if (data['isPro'] == true || data['isActive'] == true) {
      return 'Active';
    }
    return 'Verified';
  }

  static String _readString(Object? raw) => raw?.toString().trim() ?? '';

  static DateTime? _readDate(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final millis = int.tryParse(text);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return DateTime.tryParse(text);
  }

  static String? _maskOrderId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    if (value.length <= 6) {
      return value;
    }
    return '...${value.substring(value.length - 6)}';
  }
}

class _PurchaseInvoicePlan {
  const _PurchaseInvoicePlan({required this.name, required this.price});

  final String name;
  final String price;
}
