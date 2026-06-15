import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocationArea {
  const AppLocationArea({
    required this.state,
    required this.district,
    required this.city,
    required this.countryCode,
    required this.updatedAtMillis,
  });

  final String state;
  final String district;
  final String city;
  final String countryCode;
  final int updatedAtMillis;

  bool get hasArea =>
      state.trim().isNotEmpty ||
      district.trim().isNotEmpty ||
      city.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'state': state,
      'district': district,
      'city': city,
      'countryCode': countryCode,
      'updatedAt': updatedAtMillis,
    };
  }

  factory AppLocationArea.fromMap(Map<String, dynamic> map) {
    return AppLocationArea(
      state: (map['state'] ?? '').toString().trim(),
      district: (map['district'] ?? '').toString().trim(),
      city: (map['city'] ?? '').toString().trim(),
      countryCode: (map['countryCode'] ?? '').toString().trim(),
      updatedAtMillis: _readInt(map['updatedAt']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

enum AppLocationSyncResult {
  synced,
  serviceDisabled,
  permissionDenied,
  permanentlyDenied,
  failed,
}

class AppLocationService {
  AppLocationService._();

  static final AppLocationService instance = AppLocationService._();

  static const String _enabledKey = 'mana_poster_location_enabled';
  static const String _areaKey = 'mana_poster_location_area';
  static const String _feedSeedKey = 'mana_poster_status_feed_seed';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isLocationEnabledLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<AppLocationArea?> loadLocationArea() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_areaKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final area = AppLocationArea.fromMap(decoded);
        return area.hasArea ? area : null;
      }
      if (decoded is Map) {
        final area = AppLocationArea.fromMap(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
        return area.hasArea ? area : null;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<String> getOrCreateStatusFeedSeed() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getString(_feedSeedKey) ?? '').trim();
    if (existing.length >= 8) {
      return existing;
    }
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final seed = List<String>.generate(
      12,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    await prefs.setString(_feedSeedKey, seed);
    await _syncFeedSeed(seed);
    return seed;
  }

  Future<AppLocationSyncResult> requestAndSyncApproxLocation() async {
    try {
      await getOrCreateStatusFeedSeed();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _setLocationEnabled(false);
        return AppLocationSyncResult.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        await _setLocationEnabled(false);
        return AppLocationSyncResult.permissionDenied;
      }
      if (permission == LocationPermission.deniedForever) {
        await _setLocationEnabled(false);
        return AppLocationSyncResult.permanentlyDenied;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
      final first = placemarks.isEmpty ? const Placemark() : placemarks.first;
      final now = DateTime.now().millisecondsSinceEpoch;
      final city = _firstPlacemarkValue(
        placemarks,
        (item) => item.locality,
      ).ifEmpty(_firstPlacemarkValue(placemarks, (item) => item.subLocality));
      final district = _firstExactDistrict(placemarks);
      final area = AppLocationArea(
        state: _firstPlacemarkValue(
          placemarks,
          (item) => item.administrativeArea,
        ).ifEmpty(first.administrativeArea ?? ''),
        district: district,
        city: city,
        countryCode: _firstPlacemarkValue(
          placemarks,
          (item) => item.isoCountryCode,
        ).ifEmpty(first.isoCountryCode ?? ''),
        updatedAtMillis: now,
      );
      await _saveAndSyncArea(area);
      return AppLocationSyncResult.synced;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AppLocationService sync failed: $error');
      }
      return AppLocationSyncResult.failed;
    }
  }

  Future<void> _saveAndSyncArea(AppLocationArea area) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setString(_areaKey, jsonEncode(area.toMap()));
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(<String, dynamic>{
          'locationEnabled': true,
          'locationArea': area.toMap(),
          'locationUpdatedAt': area.updatedAtMillis,
          'statusFeedSeed': await getOrCreateStatusFeedSeed(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 5));
  }

  Future<void> _setLocationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(<String, dynamic>{
          'locationEnabled': enabled,
          'statusFeedSeed': await getOrCreateStatusFeedSeed(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 5));
  }

  Future<void> _syncFeedSeed(String seed) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(<String, dynamic>{
            'statusFeedSeed': seed,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Local seed is enough for feed mixing; remote sync can retry later.
    }
  }

  static String _firstPlacemarkValue(
    List<Placemark> placemarks,
    String? Function(Placemark item) read,
  ) {
    for (final item in placemarks) {
      final value = (read(item) ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static String _firstExactDistrict(List<Placemark> placemarks) {
    for (final item in placemarks) {
      final district = (item.subAdministrativeArea ?? '').trim();
      if (district.isNotEmpty) {
        return district;
      }
    }
    return '';
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback.trim() : trim();
}
