import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/auth/auth_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import '../settings/settings_page.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _busy = false;
  DateTime? _lastBackup;
  bool _loadingBackupTime = true;

  @override
  void initState() {
    super.initState();
    _refreshLastBackup();
  }

  Future<void> _refreshLastBackup() async {
    try {
      final t = await ref.read(syncServiceProvider).lastBackupAt();
      if (!mounted) return;
      setState(() {
        _lastBackup = t;
        _loadingBackupTime = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingBackupTime = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content:
            Text(msg, style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    try {
      await ref.read(syncServiceProvider).pushAll();
      await _refreshLastBackup();
      if (mounted) _toast('Backup complete.');
    } catch (e) {
      if (mounted) _toast('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    final ok = await _confirm(
      title: 'Restore from cloud?',
      body:
          'This will overwrite local entries with the cloud backup. Continue?',
      action: 'Restore',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(syncServiceProvider).pullAll();
      if (mounted) _toast('Restored from cloud.');
    } catch (e) {
      if (mounted) _toast('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await _confirm(
      title: 'Sign out?',
      body:
          'Your local data stays on this device. Sign in again to keep syncing.',
      action: 'Sign out',
    );
    if (!ok) return;
    try {
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) _toast('Sign out failed: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await _confirm(
      title: 'Delete account?',
      body:
          'Your Firebase account and cloud backup will be deleted. Local data stays on this device.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      if (mounted) _toast(e.message);
    } catch (e) {
      if (mounted) {
        _toast('Could not delete. You may need to sign in again first.');
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.sectionTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(body, style: AppText.body),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel',
                        style: AppText.body
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      action,
                      style: AppText.body.copyWith(
                        color: destructive
                            ? const Color(0xFFFF6B6B)
                            : AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, color: AppColors.accent),
          ),
        ),
      );
    }
    if (user.isAnonymous) {
      return _AnonymousUpgradeView(uid: user.uid);
    }
    final email = user.email ?? '';
    final name = user.displayName ??
        (user.email?.split('@').first ?? 'Signed in');
    final photoUrl = user.photoURL;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Account', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        shape: BoxShape.circle,
                        image: photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: photoUrl == null
                          ? Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '·',
                              style: AppText.sectionTitle
                                  .copyWith(fontSize: 20))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: AppText.sectionTitle
                                  .copyWith(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(email, style: AppText.meta),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('CLOUD BACKUP', style: AppText.label),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_done_rounded,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('Last backup', style: AppText.body),
                        const Spacer(),
                        Text(
                          _loadingBackupTime
                              ? '—'
                              : _lastBackup == null
                                  ? 'Never'
                                  : DateFormat('MMM d, h:mm a')
                                      .format(_lastBackup!.toLocal()),
                          style: AppText.meta.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            label: _busy ? '…' : 'Backup now',
                            icon: Icons.cloud_upload_rounded,
                            onTap: _busy ? null : _backupNow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SecondaryButton(
                            label: 'Restore',
                            icon: Icons.cloud_download_rounded,
                            onTap: _busy ? null : _restoreFromCloud,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Progress photos and body measurements never leave your device.',
                      style: AppText.meta.copyWith(
                          fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('PREFERENCES', style: AppText.label),
              const SizedBox(height: 10),
              _ListTile(
                icon: Icons.tune_rounded,
                label: 'Settings',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SettingsPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('ACCOUNT', style: AppText.label),
              const SizedBox(height: 10),
              _ListTile(
                icon: Icons.logout_rounded,
                label: 'Sign out',
                onTap: _signOut,
              ),
              const SizedBox(height: 8),
              _ListTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete account',
                destructive: true,
                onTap: _deleteAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: enabled ? AppColors.textPrimary : AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnonymousUpgradeView extends ConsumerStatefulWidget {
  final String uid;
  const _AnonymousUpgradeView({required this.uid});

  @override
  ConsumerState<_AnonymousUpgradeView> createState() =>
      _AnonymousUpgradeViewState();
}

class _AnonymousUpgradeViewState extends ConsumerState<_AnonymousUpgradeView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  bool _createMode = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(msg,
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
  }

  Future<void> _submitEmail() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pwd = _password.text;
    if (email.isEmpty || pwd.isEmpty) {
      _toast('Enter your email and password.');
      return;
    }
    if (_createMode && name.isEmpty) {
      _toast('What should we call you?');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).linkWithEmailPassword(
            email,
            pwd,
            createAccount: _createMode,
            displayName: name,
          );
      if (mounted) _toast('Account ready. Your data is now backed up.');
    } catch (e) {
      if (!mounted) return;
      _toast(e is AuthException ? e.message : 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueGoogle() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).linkWithGoogle();
      if (mounted) _toast('Linked with Google. Your data is now backed up.');
    } catch (e) {
      if (!mounted) return;
      _toast(e is AuthException ? e.message : 'Sign-in failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Account', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.person_outline_rounded,
                          color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guest account',
                              style: AppText.sectionTitle
                                  .copyWith(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Backing up under a temporary ID',
                              style: AppText.meta.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('UPGRADE TO A FULL ACCOUNT', style: AppText.label),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add an email or Google account so you can sign in on another device and never lose your progress.',
                      style: AppText.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (_createMode) ...[
                      Text('YOUR NAME', style: AppText.label),
                      const SizedBox(height: 6),
                      _MiniField(
                        controller: _name,
                        hint: 'How should we greet you?',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text('EMAIL', style: AppText.label),
                    const SizedBox(height: 6),
                    _MiniField(
                      controller: _email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    Text('PASSWORD', style: AppText.label),
                    const SizedBox(height: 6),
                    _MiniField(
                      controller: _password,
                      hint:
                          _createMode ? 'At least 6 characters' : 'Your password',
                      obscure: !_showPassword,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _showPassword = !_showPassword),
                        child: Icon(
                          _showPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textTertiary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _busy ? null : _submitEmail,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        decoration: BoxDecoration(
                          color: _busy
                              ? AppColors.accent.withValues(alpha: 0.5)
                              : AppColors.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.2, color: Colors.black))
                            : Text(
                                _createMode
                                    ? 'Create account & link'
                                    : 'Sign in & link',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: _busy
                            ? null
                            : () =>
                                setState(() => _createMode = !_createMode),
                        child: Text(
                          _createMode
                              ? 'Already have an account? Sign in'
                              : 'New here? Create an account',
                          style: AppText.meta.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: AppColors.stroke, height: 1)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('or',
                              style: AppText.meta.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  letterSpacing: 1)),
                        ),
                        Expanded(
                            child: Divider(
                                color: AppColors.stroke, height: 1)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _busy ? null : _continueGoogle,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: AppText.sectionTitle.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Your guest data is already backed up to Firebase. Linking just lets you sign in from another device.',
                style: AppText.meta.copyWith(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  const _MiniField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              cursorColor: AppColors.accent,
              style: AppText.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: hint,
                hintStyle: AppText.body.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            suffix!,
          ],
        ],
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _ListTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFFF6B6B) : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppText.body.copyWith(
                      color: color, fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
