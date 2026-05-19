# VerLink — Instrucciones para Claude Code

## TDD — Test Driven Development (Obligatorio)

Todo desarrollo en este proyecto sigue TDD estricto. Sin excepcion.

### Ciclo obligatorio por cada funcionalidad

1. **RED** — Escribir el test que falla primero
2. **GREEN** — Escribir el minimo codigo para que el test pase
3. **REFACTOR** — Mejorar sin romper los tests

### Reglas

- Nunca escribir implementacion sin un test previo que falle
- Cada metodo publico de AppDatabase tiene test unitario
- Cada provider de Riverpod tiene test de estado
- Cada pantalla tiene al menos un widget test
- Ejecutar `flutter test` antes de cada commit y verificar que pasa
- Si un test falla, no hacer commit

### Estructura de tests

```
test/
├── helpers/
│   ├── database_helper.dart   # createTestDatabase() — DB en memoria
│   └── provider_helper.dart   # createTestContainer(), buildTestWidget()
├── core/
│   └── database/
│       └── database_test.dart
└── features/
    ├── home/
    ├── saved/
    ├── priority/
    ├── search/
    ├── detail/
    └── capture/
```

### Helpers disponibles para tests

```dart
// DB en memoria (unit tests)
final db = createTestDatabase();

// ProviderContainer con DB en memoria (provider tests)
final container = createTestContainer();

// Widget envuelto en ProviderScope con DB en memoria (widget tests)
await tester.pumpWidget(buildTestWidget(MiWidget()));
```

### Comandos

```bash
flutter test                          # todos los tests
flutter test test/core/               # solo unit tests
flutter test --coverage               # con cobertura
```

## Idioma

Toda comunicacion con el usuario en español.

## Commits

Siempre verificar que `flutter test` pasa antes de hacer commit.
