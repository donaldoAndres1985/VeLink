# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Idioma

Toda comunicación con el usuario en español.

---

## Comandos de desarrollo

```bash
# Ejecutar todos los tests (obligatorio antes de commit)
flutter test

# Test de un archivo específico
flutter test test/core/database/database_test.dart

# Test con cobertura
flutter test --coverage

# Generar código (Drift + Riverpod) tras modificar tablas o anotaciones
flutter pub run build_runner build --delete-conflicting-outputs

# Compilar APK debug
flutter build apk --debug

# Compilar APK release
flutter build apk --release
```

---

## TDD — Obligatorio

Ciclo estricto por cada funcionalidad:

1. **RED** — Escribir el test que falla primero
2. **GREEN** — Mínimo código para que el test pase
3. **REFACTOR** — Mejorar sin romper tests

Reglas:
- Nunca escribir implementación sin un test previo que falle
- Cada método público de `AppDatabase` tiene test unitario
- Cada provider de Riverpod tiene test de estado
- Cada pantalla tiene al menos un widget test
- `flutter test` debe pasar antes de cada commit

### Helpers de test disponibles

```dart
// DB en memoria para unit tests
final db = AppDatabase.forTesting(NativeDatabase.memory());

// ProviderContainer con overrides básicos para provider tests
final container = createTestContainer();                    // test/helpers/provider_helper.dart

// Widget con ProviderScope + MaterialApp para widget tests
await tester.pumpWidget(buildTestWidget(MiWidget()));      // test/helpers/provider_helper.dart
```

`createTestContainer()` y `buildTestWidget()` ya inyectan: `databaseProvider` (en memoria), `appStringsProvider` (español), `notificationsEnabledProvider` (`_FakePrefs`). Agrega overrides adicionales con el parámetro `overrides: [...]`.

---

## Arquitectura

### Estructura de carpetas

```
lib/
├── main.dart                    # Inyecta SharedPreferences, arranca ProviderScope
├── app/app.dart                 # VerLinkApp (MaterialApp) + MainShell (navegación)
├── core/
│   ├── database/
│   │   ├── database.dart        # AppDatabase (Drift) + databaseProvider
│   │   ├── database.g.dart      # GENERADO — no editar
│   │   └── tables/              # 5 tablas: Links, Tags, LinkTags, Collections, LinkCollections
│   ├── l10n/app_strings.dart    # Localización manual (es/en), NO usa gen_l10n
│   ├── preferences/
│   │   ├── preferences_service.dart   # Interfaz + SharedPreferencesService
│   │   └── preferences_provider.dart  # Providers: theme, locale, notifications, streak, premium
│   └── theme/app_theme.dart     # AppTheme.light/dark + VeLinkSemanticColors (ThemeExtension)
├── features/
│   ├── capture/                 # Guardar link: metadata OG, image picker, share intent
│   ├── collections/             # Colecciones (CRUD + detalle + organizar)
│   ├── detail/                  # Vista detalle de un link
│   ├── home/                    # Pantalla principal: lista + filtros + resurface
│   ├── notifications/           # flutter_local_notifications
│   ├── pending/                 # Links sin revisar (isRead=false)
│   ├── premium/                 # Paywall (PaywallScreen)
│   ├── search/                  # Búsqueda
│   ├── settings/                # Ajustes: tema, idioma, notificaciones, backup, legal
│   ├── stats/                   # Estadísticas y logros (premium)
│   └── tags/                    # Etiquetas (CRUD)
├── shared/widgets/              # LinkCard, SwipeableLinkCard, ScreenHeader
└── assets/logo/
```

### Navegación

`MainShell` (en `app/app.dart`) usa un `PageView` con `_KeepAlivePage` para mantener el estado de las 4 pestañas:

| Índice | Pantalla | FAB |
|--------|----------|-----|
| 0 | `HomeScreen` | ✅ Agregar link |
| 1 | `PendientesScreen` | ✗ |
| 2 | `OrganizeScreen` | ✅ Nueva colección/tag |
| 3 | `AjustesScreen` | ✗ |

La barra de navegación es un widget personalizado `_FloatingNavBar` (no el `BottomNavigationBar` estándar).

Al iniciar, `MainShell._startUp()` inicializa notificaciones y muestra una notificación si hay links prioritarios.

### Base de datos (Drift)

`AppDatabase` en `core/database/database.dart` — esquema v2.

**5 tablas:** `Links`, `Tags`, `LinkTags`, `Collections`, `LinkCollections`.

`Links` contiene: `url`, `title`, `description`, `previewImageUrl`, `previewImagePath`, `platform`, `faviconUrl`, `isFavorite`, `priority` (int), `isRead`, `remindAt`, `notes`, `createdAt`.

Métodos clave: `watchAllLinks()`, `watchPendingLinks()`, `watchFavoriteLinks()`, `watchLinksByTag(tagId)`, `watchLinksInCollection(collectionId)`, `watchForgottenLinks()`, `getLinkStats()`.

Para tests: `AppDatabase.forTesting(NativeDatabase.memory())`.

El provider `databaseProvider` hace `ref.onDispose(db.close)`.

### Estado global (Riverpod)

Patrones usados:
- **`StreamProvider`** — para queries reactivas de la DB (`recentLinksProvider`, `filteredHomeLinksProvider`, etc.)
- **`StateNotifierProvider`** — para estado mutable con lógica (`ThemeModeNotifier`, `StreakNotifier`, `PremiumNotifier`)
- **`StateProvider`** — para estado simple (`homeFilterProvider`, `selectedPlatformProvider`)
- **`Provider`** — para servicios y valores derivados (`databaseProvider`, `appStringsProvider`)

`sharedPreferencesProvider` es un `Provider` que lanza `UnimplementedError` por defecto y **debe** ser sobreescrito en `main()` y en tests.

### Localización

`AppStrings` en `core/l10n/app_strings.dart` es una clase manual (no ARB/gen_l10n). Recibe el código de idioma en el constructor. El provider `appStringsProvider` la deriva de `localePrefProvider`. Para usar strings: `final s = ref.watch(appStringsProvider);`.

Idiomas soportados: `es` (por defecto) y `en`.

### Sistema de tema

`AppTheme.light` y `AppTheme.dark` (Material 3). Para colores semánticos que cambian entre temas, usar siempre `VeLinkSemanticColors.of(context)` (ThemeExtension). Los colores estáticos de la marca están en `VerLinkColors` (ej. `VerLinkColors.green`).

### Sistema premium

`premiumProvider` (bool en `SharedPreferences`). En modo gratuito: límite de 3 colecciones. Para navegar al paywall: `Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()))`. La activación actual es simulada (sin pago real).

### Flujo de captura de links

1. **Desde la app**: FAB en HomeScreen → detecta URL en portapapeles → `CaptureScreen(url: ...)`.
2. **Desde Share Sheet externo**: `ReceiveSharingIntentService` emite en `captureProvider` → `MainShell` escucha y navega a `CaptureScreen`.
3. **En `CaptureScreen`**: `DioMetadataService` fetcha Open Graph (título, descripción, imagen). `PlatformDetectorService` infiere la plataforma (YouTube, Twitter, etc.).

### Generación de código

Las tablas Drift tienen `part 'database.g.dart'`. Después de modificar cualquier tabla en `core/database/tables/` o añadir anotaciones de Riverpod, ejecutar:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
