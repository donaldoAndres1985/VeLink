import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../features/backup/services/backup_service.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/premium/screens/paywall_screen.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = VeLinkSemanticColors.of(context);
    final s = ref.watch(appStringsProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final currentLocale = ref.watch(localePrefProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final permAsync = ref.watch(notifPermissionProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: s.navSettings, subtitle: s.settingsSubtitle),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  AppTheme.contentBottomPadding + 16,
                ),
                children: [
                  _SectionLabel(title: s.settingsAppearance),
                  _SettingsCard(children: [
                    _ThemeTile(
                      label: s.themeLight,
                      subtitle: s.themeLightSubtitle,
                      icon: Icons.light_mode_outlined,
                      themeKey: 'theme_light',
                      selected: currentThemeMode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(ThemeMode.light),
                    ),
                    const _CardDivider(),
                    _ThemeTile(
                      label: s.themeDark,
                      subtitle: s.themeDarkSubtitle,
                      icon: Icons.dark_mode_outlined,
                      themeKey: 'theme_dark',
                      selected: currentThemeMode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(ThemeMode.dark),
                    ),
                  ]),
                  _SectionLabel(title: s.settingsLanguage),
                  _SettingsCard(children: [
                    _LanguageTile(
                      label: s.languageSpanish,
                      subtitle: 'Idioma de la aplicación',
                      langCode: 'es',
                      selected: currentLocale.languageCode == 'es',
                      onTap: () => ref
                          .read(localePrefProvider.notifier)
                          .setLocale(const Locale('es')),
                    ),
                    const _CardDivider(),
                    _LanguageTile(
                      label: s.languageEnglish,
                      subtitle: 'App language',
                      langCode: 'en',
                      selected: currentLocale.languageCode == 'en',
                      onTap: () => ref
                          .read(localePrefProvider.notifier)
                          .setLocale(const Locale('en')),
                    ),
                  ]),
                  _SectionLabel(title: s.settingsNotifications),
                  _SettingsCard(children: [
                    _NotificationTile(
                      s: s,
                      notificationsEnabled: notificationsEnabled,
                      permAsync: permAsync,
                      onChanged: (value) async {
                        await ref
                            .read(notificationsEnabledProvider.notifier)
                            .setEnabled(value);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value
                                  ? s.notificationsEnabledMsg
                                  : s.notificationsDisabledMsg),
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      },
                    ),
                  ]),
                  _SectionLabel(title: s.settingsLegal),
                  _SettingsCard(children: [
                    Semantics(
                      label: s.privacyPolicyTitle,
                      button: true,
                      child: _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: s.privacyPolicyTitle,
                        subtitle: s.privacyPolicySubtitle,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: vc.textTertiary,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _LegalPage(
                              title: s.privacyPolicyTitle,
                              body: s.privacyPolicyBody,
                            ),
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
                        trailing: Icon(
                          Icons.chevron_right,
                          color: vc.textTertiary,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _LegalPage(
                              title: s.termsTitle,
                              body: s.termsBody,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  _SectionLabel(title: s.settingsDataSection),
                  _SettingsCard(children: [
                    Semantics(
                      label: s.settingsExportData,
                      button: true,
                      child: _SettingsTile(
                        icon: Icons.upload_outlined,
                        title: s.settingsExportData,
                        subtitle: s.settingsExportDataSubtitle,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: vc.textTertiary,
                        ),
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
                        trailing: Icon(
                          Icons.chevron_right,
                          color: vc.textTertiary,
                        ),
                        onTap: () => _importData(context, ref, s),
                      ),
                    ),
                    const _CardDivider(),
                    Semantics(
                      label: s.settingsDeleteMyData,
                      button: true,
                      child: _SettingsTile(
                        icon: Icons.delete_forever_outlined,
                        iconColor: VerLinkColors.error,
                        title: s.settingsDeleteMyData,
                        titleColor: VerLinkColors.error,
                        subtitle: s.deleteMyDataSubtitle,
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: VerLinkColors.error,
                        ),
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
                        trailing: Icon(
                          Icons.chevron_right,
                          color: vc.textTertiary,
                        ),
                        onTap: () =>
                            launchUrl(Uri.parse('mailto:soporte@verlink.app')),
                      ),
                    ),
                  ]),
                  _SectionLabel(title: s.settingsPremiumSection),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: const Color(0xFFEAB308),
                      title: s.premiumTitle,
                      subtitle: s.premiumSubtitle,
                      trailing: Icon(Icons.chevron_right, color: vc.textTertiary),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      ),
                    ),
                  ]),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(
      BuildContext context, WidgetRef ref, AppStrings s) async {
    try {
      await ref.read(backupServiceProvider).exportToJson();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.settingsExportError),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _importData(
      BuildContext context, WidgetRef ref, AppStrings s) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null || picked.files.single.path == null) return;
    if (!context.mounted) return;

    final filePath = picked.files.single.path!;
    final service = ref.read(backupServiceProvider);
    final preview = await service.readBackupPreview(filePath);
    if (!context.mounted) return;

    if (preview == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.importFileNotFound),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final linksCount = (preview['links'] as List?)?.length ?? 0;
    final tagsCount = (preview['tags'] as List?)?.length ?? 0;
    final collsCount = (preview['collections'] as List?)?.length ?? 0;

    // Elegir modo: Combinar o Reemplazar
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final vc = VeLinkSemanticColors.of(ctx);
        return AlertDialog(
          title: Text(s.importChooseMode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.importPreviewMsg(linksCount, tagsCount, collsCount),
                style: TextStyle(fontSize: 13, color: vc.textSecondary),
              ),
              const SizedBox(height: 16),
              _ImportModeOption(
                icon: Icons.merge_rounded,
                title: s.importMerge,
                desc: s.importMergeDesc,
                onTap: () => Navigator.pop(ctx, false),
              ),
              const SizedBox(height: 8),
              _ImportModeOption(
                icon: Icons.delete_sweep_rounded,
                title: s.importReplace,
                desc: s.importReplaceDesc,
                isDestructive: true,
                onTap: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 4),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(s.cancel),
            ),
          ],
        );
      },
    );
    if (replace == null || !context.mounted) return;

    try {
      final result = await service.importFromJson(filePath, replace: replace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.importSuccessMsg(result.imported, result.skipped)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // Best-effort, en segundo plano: no bloquea el mensaje de éxito ni la
      // pantalla. Las previews de los links importados van completándose
      // solas a medida que la UI reacciona a los cambios en la base.
      unawaited(service.cacheMissingPreviewImages());
    } on InvalidBackupException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.importInvalidFile),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      // Cualquier otro fallo a mitad de la importación (registro corrupto,
      // I/O, etc.): la transacción ya revirtió los cambios en BackupService,
      // pero el usuario debe enterarse en vez de creer que se importó todo.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.importGenericError),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _confirmDeleteData(
      BuildContext context, WidgetRef ref, AppStrings s) {
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
              style: FilledButton.styleFrom(
                backgroundColor: VerLinkColors.error,
              ),
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
    final vc = VeLinkSemanticColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: vc.textTertiary,
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
    final vc = VeLinkSemanticColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: vc.shadow06,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    final vc = VeLinkSemanticColors.of(context);
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 0,
      color: vc.outlineVariant,
    );
  }
}

class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color? color;
  const _IconContainer({required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? VerLinkColors.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: c.withAlpha(25),
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
    final vc = VeLinkSemanticColors.of(context);
    return ListTile(
      leading: _IconContainer(icon: icon, color: iconColor),
      title: Text(
        title,
        style: titleColor != null
            ? TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              )
            : TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: vc.textPrimary,
              ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: vc.textSecondary,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      minVerticalPadding: 4,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
    final vc = VeLinkSemanticColors.of(context);
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: ListTile(
        key: Key('lang_$langCode'),
        leading: const _IconContainer(icon: Icons.language),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: vc.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: vc.textSecondary,
          ),
        ),
        trailing: selected
            ? const Icon(
                Icons.check_circle_rounded,
                color: VerLinkColors.primary,
              )
            : Icon(
                Icons.radio_button_unchecked,
                color: vc.textTertiary,
              ),
        onTap: onTap,
        selected: selected,
        minVerticalPadding: 4,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
    final vc = VeLinkSemanticColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('notifications_switch'),
          secondary: _IconContainer(
            icon: notificationsEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
          ),
          title: Text(
            s.settingsNotifications,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: vc.textPrimary,
            ),
          ),
          subtitle: Text(
            s.notificationsSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: vc.textSecondary,
            ),
          ),
          value: notificationsEnabled,
          onChanged: onChanged,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        ),
        permAsync.maybeWhen(
          data: (granted) => (notificationsEnabled && !granted)
              ? _PermissionWarningTile(message: s.notifPermissionBlocked)
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
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
    final vc = VeLinkSemanticColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: vc.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: vc.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final String themeKey;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.themeKey,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vc = VeLinkSemanticColors.of(context);
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: ListTile(
        key: Key(themeKey),
        leading: _IconContainer(icon: icon),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: vc.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: vc.textSecondary,
          ),
        ),
        trailing: selected
            ? const Icon(
                Icons.check_circle_rounded,
                color: VerLinkColors.primary,
              )
            : Icon(
                Icons.radio_button_unchecked,
                color: vc.textTertiary,
              ),
        onTap: onTap,
        selected: selected,
        minVerticalPadding: 4,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      ),
    );
  }
}

class _ImportModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ImportModeOption({
    required this.icon,
    required this.title,
    required this.desc,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vc = VeLinkSemanticColors.of(context);
    final color = isDestructive ? VerLinkColors.error : VerLinkColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: isDestructive ? VerLinkColors.error.withAlpha(80) : vc.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: TextStyle(fontSize: 12, color: vc.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: vc.textTertiary),
          ],
        ),
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
      body: Builder(builder: (context) {
        final vc = VeLinkSemanticColors.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          child: Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: vc.textSecondary,
            ),
          ),
        );
      }),
    );
  }
}
