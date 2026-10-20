import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminSession extends ChangeNotifier {
  User? user;

  /// null = unknown (still checking), true/false = known
  bool? isAdmin;

  bool loading = true;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _adminSub;

  AdminSession() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? u) {
    user = u;

    _adminSub?.cancel();
    _adminSub = null;

    if (u == null) {
      isAdmin = false;
      loading = false;
      notifyListeners();
      return;
    }

    // OPTIONAL hardening (only if you use email/password for admins):
    // if (u.email != null && !u.emailVerified) {
    //   isAdmin = false;
    //   loading = false;
    //   notifyListeners();
    //   return;
    // }

    // While checking admins/{uid}, mark as unknown to avoid stale UI state.
    isAdmin = null;
    loading = true;
    notifyListeners();

    _adminSub = FirebaseFirestore.instance
        .collection('admins')
        .doc(u.uid)
        .snapshots()
        .listen(
      (doc) {
        isAdmin = doc.exists;
        loading = false;
        notifyListeners();
      },
      onError: (_) {
        isAdmin = false;
        loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _adminSub?.cancel();
    super.dispose();
  }
}