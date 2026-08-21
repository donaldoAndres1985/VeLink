import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';

// ── Límites del plan gratuito ─────────────────────────────────────────────────
const int freeMaxLinks = 30;
const int freeMaxCollections = 2;
const int freeMaxTags = 3;

// ── Guards centralizados ──────────────────────────────────────────────────────

final canCreateLinkProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(premiumProvider)) return true;
  final links = await ref.read(databaseProvider).getAllLinks();
  return links.length < freeMaxLinks;
});

final canCreateCollectionProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(premiumProvider)) return true;
  final cols = await ref.read(databaseProvider).getAllCollections();
  return cols.length < freeMaxCollections;
});

final canCreateTagProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(premiumProvider)) return true;
  final tags = await ref.read(databaseProvider).getAllTags();
  return tags.length < freeMaxTags;
});

final canUseTagColorsProvider = Provider<bool>((ref) => ref.watch(premiumProvider));
final canViewFullStatsProvider = Provider<bool>((ref) => ref.watch(premiumProvider));
final canUseAdvancedBackupProvider = Provider<bool>((ref) => ref.watch(premiumProvider));
final canUseAdvancedRemindersProvider = Provider<bool>((ref) => ref.watch(premiumProvider));
