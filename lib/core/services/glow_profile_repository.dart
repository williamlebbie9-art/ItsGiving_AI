import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/glowup/glow_models.dart';

/// One source of truth for the user's aesthetic direction and safe scan context.
/// A local copy keeps the journey usable offline; Firestore makes it account-scoped.
class GlowProfileRepository {
  static const _profileKey = 'glowup_profile';

  Future<GlowUserProfile> load() async {
    final local = await _loadLocal();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return local;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final raw = snapshot.data()?['profile'];
      if (raw is Map) {
        final remote = GlowUserProfile.fromJson(Map<String, dynamic>.from(raw));
        await _saveLocal(remote);
        return remote;
      }
      if (local.buildPersonalizationSummary().isNotEmpty) await save(local);
    } catch (_) {
      // The local profile remains a safe offline fallback.
    }
    return local;
  }

  Future<void> save(GlowUserProfile profile) async {
    await _saveLocal(profile);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profile': profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Retain the local update and retry naturally on a future save/load.
    }
  }

  Future<void> saveScanSummary(String summary) async {
    final profile = await _loadLocal();
    await save(profile.copyWith(currentLookSummary: summary));
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc('latest')
          .set({
        'summary': summary,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<GlowUserProfile> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return const GlowUserProfile();
    try {
      return GlowUserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const GlowUserProfile();
    }
  }

  Future<void> _saveLocal(GlowUserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}
