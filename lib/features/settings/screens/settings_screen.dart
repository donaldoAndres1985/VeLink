import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final currentLocale = ref.watch(localePrefProvider);

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
            onTap: () => ref.read(localePrefProvider.notifier).setLocale(
                  const Locale('es'),
                ),
          ),
          _LanguageTile(
            label: s.languageEnglish,
            langCode: 'en',
            selected: currentLocale.languageCode == 'en',
            onTap: () => ref.read(localePrefProvider.notifier).setLocale(
                  const Locale('en'),
                ),
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
              await ref
                  .read(notificationsEnabledProvider.notifier)
                  .setEnabled(value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? s.notificationsEnabledMsg
                        : s.notificationsDisabledMsg),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),

          // ── Información ──────────────────────────────────────────────────
          _SectionHeader(title: s.settingsAppInfo),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('VeLink'),
            subtitle: Text(s.appDescription),
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: Text(s.appVersion),
            trailing: const Text('1.0.0', style: TextStyle(fontSize: 13)),
          ),
        ],
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
    return ListTile(
      key: Key('lang_$langCode'),
      title: Text(label),
      leading: const Icon(Icons.language),
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
      selected: selected,
    );
  }
}
