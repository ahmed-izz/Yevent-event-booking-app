import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const routeName = 'editProfile';
  static const routePath = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _photoUrl = TextEditingController();
  bool _loading = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final u = _user;
    _name.text = u?.displayName ?? '';
    _photoUrl.text = u?.photoURL ?? '';

    // Refresh avatar preview as user types/pastes photo URL
    _photoUrl.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _photoUrl.removeListener(_refreshPreview);
    _name.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    final u = _user;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final name = _name.text.trim();
      final url = _photoUrl.text.trim();

      await u.updateDisplayName(name);
      await u.updatePhotoURL(url.isEmpty ? null : url);
      await u.reload();

      if (!mounted) return;
      context.pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final previewUrl = _photoUrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // Preview card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  _Avatar(photoUrl: previewUrl, radius: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preview',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Display name',
                    controller: _name,
                    prefixIcon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a display name' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Photo URL (optional)',
                    controller: _photoUrl,
                    prefixIcon: Icons.link,
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      final uri = Uri.tryParse(s);
                      if (uri == null || !uri.isAbsolute) return 'Enter a valid URL';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Note: Uploading from gallery needs Firebase Storage. For now you can paste an image URL.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
                    ),
                  ),

                  const SizedBox(height: 14),

                  PrimaryButton(
                    text: _loading ? 'Saving...' : 'Save changes',
                    onPressed: _loading ? null : _save,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.radius});

  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (photoUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: cs.primary.withOpacity(0.12),
        child: Icon(Icons.person, color: cs.primary),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.surfaceVariant,
      backgroundImage: CachedNetworkImageProvider(photoUrl),
      onBackgroundImageError: (_, __) {},
    );
  }
}