import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../models/ticket.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs);

  final SharedPreferences _prefs;

  static const _kSeenOnboarding = 'seenOnboarding';
  static const _kLoggedIn = 'loggedIn';
  static const _kEmail = 'email';
  static const _kDarkMode = 'darkMode';

  bool seenOnboarding = false;
  bool loggedIn = false;
  String? email;

  bool isDarkMode = false;

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  final Set<String> favoriteEventIds = {};
  final List<Ticket> tickets = [];

  Future<void> init() async {
    seenOnboarding = _prefs.getBool(_kSeenOnboarding) ?? false;
    loggedIn = _prefs.getBool(_kLoggedIn) ?? false;
    email = _prefs.getString(_kEmail);
    isDarkMode = _prefs.getBool(_kDarkMode) ?? false;
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

  Future<void> login({required String email, required String password}) async {
    loggedIn = true;
    this.email = email;

    await _prefs.setBool(_kLoggedIn, true);
    await _prefs.setString(_kEmail, email);
    notifyListeners();
  }

  Future<void> logout() async {
    loggedIn = false;
    await _prefs.setBool(_kLoggedIn, false);
    notifyListeners();
  }

  void toggleFavorite(Event event) {
    if (favoriteEventIds.contains(event.id)) {
      favoriteEventIds.remove(event.id);
    } else {
      favoriteEventIds.add(event.id);
    }
    notifyListeners();
  }

  bool isFavorite(String eventId) => favoriteEventIds.contains(eventId);

  void addTicket(Ticket ticket) {
    tickets.insert(0, ticket);
    notifyListeners();
  }
}