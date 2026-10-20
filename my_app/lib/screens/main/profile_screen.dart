import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/app_state.dart';
import '../splash_screen.dart';
import 'account_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'main_screen.dart';
import 'privacy_security_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Must match PrivacySecurityScreen key exactly
  static const _kHideEmail = 'privacy_hide_email';

  bool _prefsLoaded = false;
  bool _hideEmail = true; // matches your PrivacySecurityScreen default

  @override
  void initState() {
    super.initState();
    _loadPrivacyPrefs();
  }

  Future<void> _loadPrivacyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _hideEmail = prefs.getBool(_kHideEmail) ?? true;
      _prefsLoaded = true;
    });
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    if (name.isEmpty) return '***@$domain';
    if (name.length == 1) return '${name[0]}***@$domain';
    if (name.length == 2) return '${name[0]}${name[1]}***@$domain';

    return '${name.substring(0, 2)}***@$domain';
  }

  Future<void> _confirmLogout() async {
    final cs = Theme.of(context).colorScheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await context.read<AppState>().logout();
    if (!mounted) return;
    context.go(SplashScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final user = FirebaseAuth.instance.currentUser;

    final baseEmail = user?.email ?? state.email ?? 'example@gmail.com';
    final shownEmail = _hideEmail ? _maskEmail(baseEmail) : baseEmail;

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (baseEmail.contains('@') ? baseEmail.split('@').first : 'User');

    final photoUrl = (user?.photoURL ?? '').trim();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            centerTitle: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withOpacity(0.95),
                      cs.primaryContainer.withOpacity(0.70),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Profile',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header card
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ProfileAvatar(
                        photoUrl: photoUrl,
                        fallbackInitial:
                            displayName.isNotEmpty ? displayName[0] : 'U',
                        onEdit: () => context.push(EditProfileScreen.routePath),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shownEmail,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (!_prefsLoaded)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Loading privacy settings…',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              context.push(EditProfileScreen.routePath),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Stats grid
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 76,
                  ),
                  children: [
                    _TicketsCountTile(
                      onTap: () =>
                          context.go('${MainScreen.routePath}?tab=tickets'),
                    ),
                    _StatTile(
                      icon: Icons.favorite_border,
                      label: 'Favorites',
                      value: '${state.favoritesCount}',
                      onTap: () =>
                          context.go('${MainScreen.routePath}?tab=favorites'),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  'Preferences',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark mode'),
                    value: state.isDarkMode,
                    onChanged: (v) => context.read<AppState>().setDarkMode(v),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Account',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Account Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push(AccountSettingsScreen.routePath),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.security_outlined),
                        title: const Text('Privacy & Security'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await context.push(PrivacySecurityScreen.routePath);
                          // refresh hideEmail when coming back
                          await _loadPrivacyPrefs();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Support',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Get Help'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => context.push(HelpScreen.routePath),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: Icon(Icons.logout, color: cs.error),
                    title: Text(
                      'Log Out',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.error,
                      ),
                    ),
                    onTap: _confirmLogout,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketsCountTile extends StatelessWidget {
  const _TicketsCountTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return _StatTile(
        icon: Icons.confirmation_number_outlined,
        label: 'Tickets',
        value: '0',
        onTap: onTap,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final value = snap.connectionState == ConnectionState.waiting
            ? '...'
            : '${snap.data?.size ?? 0}';

        return _StatTile(
          icon: Icons.confirmation_number_outlined,
          label: 'Tickets',
          value: value,
          onTap: onTap,
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.fallbackInitial,
    required this.onEdit,
  });

  final String photoUrl;
  final String fallbackInitial;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipOval(
              child: Container(
                color: cs.primary.withOpacity(0.12),
                child: photoUrl.isEmpty
                    ? Center(
                        child: Text(
                          fallbackInitial.toUpperCase(),
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: cs.surfaceVariant),
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            fallbackInitial.toUpperCase(),
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filledTonal(
              onPressed: onEdit,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}