import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../features/backup/services/backup_service.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // ── Idioma ──────────────────────────────────────────────────────
          _SectionLabel(title: s.settingsLanguage),
          _SettingsCard(children: [
            _LanguageTile(
              label: s.languageSpanish,
              subtitle: 'Idioma de la aplicación',
              langCode: 'es',
              selected: currentLocale.languageCode == 'es',
              onTap: () => ref.read(localePrefProvider.notifier).setLocale(const Locale('es')),
            ),
            const _CardDivider(),
            _LanguageTile(
              label: s.languageEnglish,
              subtitle: 'App language',
              langCode: 'en',
              selected: currentLocale.languageCode == 'en',
              onTap: () => ref.read(localePrefProvider.notifier).setLocale(const Locale('en')),
            ),
          ]),

          // ── Notificaciones ───────────────────────────────────────────────
          _SectionLabel(title: s.settingsNotifications),
          _SettingsCard(children: [
            _NotificationTile(
              s: s,
              notificationsEnabled: notificationsEnabled,
              permAsync: permAsync,
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
          ]),

          // ── Legal ────────────────────────────────────────────────────────
          _SectionLabel(title: s.settingsLegal),
          _SettingsCard(children: [
            Semantics(
              label: s.privacyPolicyTitle,
              button: true,
              child: _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: s.privacyPolicyTitle,
                subtitle: s.privacyPolicySubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _LegalPage(title: s.privacyPolicyTitle, body: s.privacyPolicyBody),
                  ),
                ),
              ),
            ),
            const _CardDivider(),
            Semantics(
              label: s.termsTitle,
              button: true,
              child: _SettingsTile(
                icon: Icons.article_outlined,
                title: s.termsTitle,
                subtitle: s.termsSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _LegalPage(title: s.termsTitle, body: s.termsBody),
                  ),
                ),
              ),
            ),
          ]),

          // ── Cuenta y datos ───────────────────────────────────────────────
          _SectionLabel(title: s.settingsDataSection),
          _SettingsCard(children: [
            Semantics(
              label: s.settingsExportData,
              button: true,
              child: _SettingsTile(
                icon: Icons.upload_outlined,
                title: s.settingsExportData,
                subtitle: s.settingsExportDataSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _exportData(context, ref, s),
              ),
            ),
            const _CardDivider(),
            Semantics(
              label: s.settingsImportData,
              button: true,
              child: _SettingsTile(
                icon: Icons.download_outlined,
                title: s.settingsImportData,
                subtitle: s.settingsImportDataSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _importData(context, ref, s),
              ),
            ),
            const _CardDivider(),
            Semantics(
              label: s.settingsDeleteMyData,
              button: true,
              child: _SettingsTile(
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.red,
                title: s.settingsDeleteMyData,
                titleColor: Colors.red,
                subtitle: s.deleteMyDataSubtitle,
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _confirmDeleteData(context, ref, s),
              ),
            ),
            const _CardDivider(),
            Semantics(
              label: s.settingsContactSupport,
              button: true,
              child: _SettingsTile(
                icon: Icons.mail_outline,
                title: s.settingsContactSupport,
                subtitle: s.contactSupportSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => launchUrl(Uri.parse('mailto:soporte@velink.app')),
              ),
            ),
          ]),

          // ── Versión ──────────────────────────────────────────────────────
          _SectionLabel(title: s.settingsAppInfo),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.tag,
              title: s.appVersion,
              subtitle: '1.0.0',
              trailing: null,
              onTap: null,
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref, AppStrings s) async {
    try {
      final path = await ref.read(backupServiceProvider).exportToJson();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.exportSuccessMsg(path)), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref, AppStrings s) async {
    final service = ref.read(backupServiceProvider);
    final preview = await service.readBackupPreview();
    if (!context.mounted) return;
    if (preview == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.importFileNotFound), duration: const Duration(seconds: 3)),
      );
      return;
    }
    final linksCount = (preview['links'] as List?)?.length ?? 0;
    final tagsCount = (preview['tags'] as List?)?.length ?? 0;
    final collsCount = (preview['collections'] as List?)?.length ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.settingsImportData),
        content: Text(s.importPreviewMsg(linksCount, tagsCount, collsCount)),
        actions: [
          Semantics(
            label: s.cancel,
            button: true,
            child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          ),
          Semantics(
            label: s.importConfirm,
            button: true,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.importConfirm),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final result = await service.importFromJson();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.importSuccessMsg(result.imported, result.skipped)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on BackupFileNotFoundException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.importFileNotFound), duration: const Duration(seconds: 3)),
        );
      }
    } on InvalidBackupException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.importInvalidFile), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  void _confirmDeleteData(BuildContext context, WidgetRef ref, AppStrings s) {
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

// ── Private widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 0,
      // ignore: deprecated_member_use
      color: Colors.white.withOpacity(0.08),
    );
  }
}

class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color? color;
  const _IconContainer({required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: c),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconContainer(icon: icon, color: iconColor),
      title: Text(title, style: titleColor != null ? TextStyle(color: titleColor) : null),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing,
      onTap: onTap,
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String langCode;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.subtitle,
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
        leading: const _IconContainer(icon: Icons.language),
        title: Text(label),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: selected
            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
            : const Icon(Icons.radio_button_unchecked),
        onTap: onTap,
        selected: selected,
        minVerticalPadding: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppStrings s;
  final bool notificationsEnabled;
  final AsyncValue<bool> permAsync;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.s,
    required this.notificationsEnabled,
    required this.permAsync,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          key: const Key('notifications_switch'),
          leading: _IconContainer(
            icon: notificationsEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
          ),
          title: Text(s.settingsNotifications),
          subtitle: Text(s.notificationsSubtitle, style: const TextStyle(fontSize: 12)),
          trailing: Switch(value: notificationsEnabled, onChanged: onChanged),
          minVerticalPadding: 14,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        ),
        permAsync.maybeWhen(
          data: (granted) => (notificationsEnabled && !granted)
              ? _PermissionWarningTile(message: s.notifPermissionBlocked)
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                notificationsEnabled ? Icons.check_circle_outline : Icons.notifications_off_outlined,
                size: 14,
                color: notificationsEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notificationsEnabled ? s.notificationsStatusEnabled : s.notificationsStatusDisabled,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionWarningTile extends StatelessWidget {
  final String message;
  const _PermissionWarningTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
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
        leading: Semantics(label: 'Back', button: true, child: const BackButton()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Text(body, style: const TextStyle(fontSize: 14, height: 1.6)),
      ),
    );
  }
}
