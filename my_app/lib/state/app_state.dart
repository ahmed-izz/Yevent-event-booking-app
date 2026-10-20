import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs);

  final SharedPreferences _prefs;

  static const _kSeenOnboarding = 'seenOnboarding';
  static const _kEmail = 'email';
  static const _kDarkMode = 'darkMode';

  // Favorites
  static const _kFavoriteEventIds = 'favoriteEventIds';
  static const _kFavoritesSyncedUid = 'favoritesSyncedUid';

  bool seenOnboarding = false;

  /// UI convenience; auth truth is FirebaseAuth.currentUser.
  String? email;

  bool isDarkMode = false;
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Favorites (in-memory)
  final Set<String> favoriteEventIds = {};
  int get favoritesCount => favoriteEventIds.length;

  // google_sign_in (mobile only; web uses signInWithPopup)
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['email']);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritesSub;

  Future<void> init() async {
    seenOnboarding = _prefs.getBool(_kSeenOnboarding) ?? false;
    isDarkMode = _prefs.getBool(_kDarkMode) ?? false;

    // Load favorites cache (device)
    final favList = _prefs.getStringList(_kFavoriteEventIds) ?? const <String>[];
    favoriteEventIds
      ..clear()
      ..addAll(favList);

    // Sync email from Firebase user (if logged in) or fallback to prefs
    final user = FirebaseAuth.instance.currentUser;
    email = user?.email ?? _prefs.getString(_kEmail);

    // Bind favorites to auth state (so favorites become account-based when signed in)
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.userChanges().listen((user) async {
      await _bindFavoritesListener(user);
    });

    // Bind immediately for current user
    await _bindFavoritesListener(FirebaseAuth.instance.currentUser);

    notifyListeners();
  }

  @override
  void dispose() {
    _favoritesSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> setDarkMode(bool value) async {
    isDarkMode = value;
    await _prefs.setBool(_kDarkMode, value);
    notifyListeners();
  }

  Future<void> toggleDarkMode() => setDarkMode(!isDarkMode);

  Future<void> completeOnboarding() async {
    seenOnboarding = true;
    await _prefs.setBool(_kSeenOnboarding, true);
    notifyListeners();
  }

  // -------------------------
  // AUTH (FirebaseAuth)
  // -------------------------

  Future<void> login({required String email, required String password}) async {
    final e = email.trim();
    if (e.isEmpty) throw 'Email is required';

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: e,
        password: password,
      );
      this.email = FirebaseAuth.instance.currentUser?.email ?? e;
      await _prefs.setString(_kEmail, this.email ?? e);
      notifyListeners();
    } on FirebaseAuthException catch (ex) {
      throw ex.message ?? ex.code;
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final e = email.trim();
    if (e.isEmpty) throw 'Email is required';

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: e,
        password: password,
      );

      if ((displayName ?? '').trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName!.trim());
      }

      this.email = cred.user?.email ?? e;
      await _prefs.setString(_kEmail, this.email ?? e);
      notifyListeners();
    } on FirebaseAuthException catch (ex) {
      throw ex.message ?? ex.code;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // WEB: Use popup
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});

        final userCred = await FirebaseAuth.instance.signInWithPopup(provider);

        email = userCred.user?.email ?? email;
        if (email != null && email!.trim().isNotEmpty) {
          await _prefs.setString(_kEmail, email!.trim());
        }

        notifyListeners();
        return;
      }

      // MOBILE: Use google_sign_in
      final account = await _googleSignIn.signIn();
      if (account == null) throw 'Canceled';

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null && accessToken == null) {
        throw 'Google sign-in failed (missing token).';
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      email = userCred.user?.email ?? email;
      if (email != null && email!.trim().isNotEmpty) {
        await _prefs.setString(_kEmail, email!.trim());
      }

      notifyListeners();
    } on FirebaseAuthException catch (ex) {
      throw ex.message ?? ex.code;
    }
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }

    await FirebaseAuth.instance.signOut();

    email = null;
    await _prefs.remove(_kEmail);

    // favorites listener will be stopped by userChanges(); we keep local cache as-is
    notifyListeners();
  }

  // -------------------------
  // Favorites (Firestore-backed when logged in)
  // -------------------------

  Future<void> _persistFavorites() async {
    await _prefs.setStringList(_kFavoriteEventIds, favoriteEventIds.toList());
  }

  Future<void> _bindFavoritesListener(User? user) async {
    await _favoritesSub?.cancel();
    _favoritesSub = null;

    if (user == null) {
      // logged out: use cached favorites (already loaded)
      notifyListeners();
      return;
    }

    // One-time: if user had local favorites while logged out, merge them into cloud.
    final lastSyncedUid = _prefs.getString(_kFavoritesSyncedUid);
    if (lastSyncedUid != user.uid && favoriteEventIds.isNotEmpty) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final col = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites');

        for (final eventId in favoriteEventIds) {
          batch.set(col.doc(eventId), {
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        await batch.commit();
        await _prefs.setString(_kFavoritesSyncedUid, user.uid);
      } catch (_) {
        // ignore; listener will still load cloud favorites if available
      }
    } else {
      await _prefs.setString(_kFavoritesSyncedUid, user.uid);
    }

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites');

    _favoritesSub = col.snapshots().listen((snap) async {
      favoriteEventIds
        ..clear()
        ..addAll(snap.docs.map((d) => d.id));

      await _persistFavorites();
      notifyListeners();
    }, onError: (_) {
      // If Firestore fails, keep whatever is currently in memory/prefs.
    });
  }

  void toggleFavorite(Event event) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final wasFav = favoriteEventIds.contains(event.id);
    if (wasFav) {
      favoriteEventIds.remove(event.id);
    } else {
      favoriteEventIds.add(event.id);
    }

    _persistFavorites();
    notifyListeners();

    // Logged out: device-only behavior (same as before)
    if (uid == null) return;

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(event.id);

    // Fire-and-forget; listener will reconcile
    if (wasFav) {
      doc.delete();
    } else {
      doc.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  bool isFavorite(String eventId) => favoriteEventIds.contains(eventId);
}