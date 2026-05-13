import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../features/notifications/providers/notification_provider.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final currentLocale = ref.watch(localePrefProvider);
    final permAsync = ref.watch(notifPermissionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        children: [
          // ── Idioma ──────────────────────────────────────────────────────
          _SectionHeader(title: s.settingsLanguage),
          _LanguageTile(
            label: s.languageSpanish,
            langCode: 'es',
            selected: currentLocale.languageCode == 'es',
            onTap: () => ref.read(localePrefProvider.notifier).setLocale(const Locale('es')),
          ),
          _LanguageTile(
            label: s.languageEnglish,
            langCode: 'en',
            selected: currentLocale.languageCode == 'en',
            onTap: () => ref.read(localePrefProvider.notifier).setLocale(const Locale('en')),
          ),
          const Divider(height: 1),

          // ── Notificaciones ───────────────────────────────────────────────
          _SectionHeader(title: s.settingsNotifications),
          SwitchListTile(
            key: const Key('notifications_switch'),
            title: Text(s.settingsNotifications),
            secondary: Icon(
              notificationsEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
            value: notificationsEnabled,
            onChanged: (value) async {
              await ref.read(notificationsEnabledProvider.notifier).setEnabled(value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? s.notificationsEnabledMsg : s.notificationsDisabledMsg),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              }
            },
          ),
          if (notificationsEnabled)
            permAsync.maybeWhen(
              data: (granted) => granted
                  ? const SizedBox.shrink()
                  : _PermissionWarningTile(message: s.notifPermissionBlocked),
              orElse: () => const SizedBox.shrink(),
            ),
          const Divider(height: 1),

          // ── Legal ────────────────────────────────────────────────────────
          _SectionHeader(title: s.settingsLegal),
          Semantics(
            label: s.privacyPolicyTitle,
            button: true,
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(s.privacyPolicyTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _LegalPage(title: s.privacyPolicyTitle, body: s.privacyPolicyBody),
                ),
              ),
            ),
          ),
          Semantics(
            label: s.termsTitle,
            button: true,
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(s.termsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _LegalPage(title: s.termsTitle, body: s.termsBody),
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // ── Cuenta y datos ───────────────────────────────────────────────
          _SectionHeader(title: s.settingsDataSection),
          Semantics(
            label: s.settingsDeleteMyData,
            button: true,
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: Text(s.settingsDeleteMyData, style: const TextStyle(color: Colors.red)),
              onTap: () => _confirmDeleteData(context, ref, s),
            ),
          ),
          Semantics(
            label: s.settingsContactSupport,
            button: true,
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(s.settingsContactSupport),
              onTap: () => launchUrl(Uri.parse('mailto:soporte@velink.app')),
            ),
          ),
          const Divider(height: 1),

          // ── Versión ──────────────────────────────────────────────────────
          _SectionHeader(title: s.settingsAppInfo),
          ListTile(
            leading: const Icon(Icons.tag),
            title: Text(s.appVersion),
            trailing: const Text('1.0.0', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteData(BuildContext context, WidgetRef ref, dynamic s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.settingsDeleteMyData),
        content: Text(s.deleteDataWarning),
        actions: [
          Semantics(
            label: s.cancel,
            button: true,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
          ),
          Semantics(
            label: s.deleteDataConfirm,
            button: true,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(databaseProvider).deleteAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s.deleteDataSuccess),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                }
              },
              child: Text(s.deleteDataConfirm),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionWarningTile extends StatelessWidget {
  final String message;
  const _PermissionWarningTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String body;
  const _LegalPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Semantics(
          label: 'Back',
          button: true,
          child: const BackButton(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(body, style: const TextStyle(fontSize: 14, height: 1.6)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String langCode;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.langCode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: ListTile(
        key: Key('lang_$langCode'),
        title: Text(label),
        leading: const Icon(Icons.language),
        trailing: selected
            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
            : const Icon(Icons.radio_button_unchecked),
        onTap: onTap,
        selected: selected,
      ),
    );
  }
}
