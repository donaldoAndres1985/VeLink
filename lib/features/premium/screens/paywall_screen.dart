import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final vc = VeLinkSemanticColors.of(context);

    return Scaffold(
      backgroundColor: vc.surface,
      appBar: AppBar(
        backgroundColor: vc.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: vc.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 24),
                  // Header
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEAB308), Color(0xFFF97316)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEAB308).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.premiumTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: vc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.premiumSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: vc.textSecondary),
                  ),
                  const SizedBox(height: 36),
                  // Features
                  ..._features(s).map((f) => _FeatureRow(feature: f, vc: vc)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VerLinkColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  // TODO: Integrar RevenueCat antes de publicar en tiendas
                  onPressed: () => _activate(context, ref, s),
                  child: Text(
                    s.premiumUpgradeAction,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            TextButton(
              // TODO: Implementar restore purchase con RevenueCat
              onPressed: () {},
              child: Text(
                s.premiumRestorePurchase,
                style: TextStyle(fontSize: 14, color: vc.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                s.premiumMaybeLater,
                style: TextStyle(fontSize: 14, color: vc.textTertiary),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _activate(BuildContext context, WidgetRef ref, AppStrings s) async {
    await ref.read(premiumProvider.notifier).upgrade();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.premiumActive),
        backgroundColor: VerLinkColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static List<_Feature> _features(AppStrings s) => [
        _Feature(Icons.link_rounded, s.premiumFeatureLinks),
        _Feature(Icons.folder_copy_rounded, s.premiumFeatureCollections),
        _Feature(Icons.label_rounded, s.premiumFeatureTags),
        _Feature(Icons.bar_chart_rounded, s.premiumFeatureStats),
        _Feature(Icons.emoji_events_rounded, s.premiumFeatureBadges),
        _Feature(Icons.folder_special_rounded, s.premiumFeatureOrganize),
        _Feature(Icons.backup_rounded, s.premiumFeatureBackup),
      ];
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  final VeLinkSemanticColors vc;

  const _FeatureRow({required this.feature, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VerLinkColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, size: 18, color: VerLinkColors.primary),
          ),
          const SizedBox(width: 14),
          Text(
            feature.label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: vc.textPrimary),
          ),
        ],
      ),
    );
  }
}
