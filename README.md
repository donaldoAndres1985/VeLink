<div align="center">

# VerLink

**Tu segunda memoria digital**

Guarda, organiza y redescubre todo el contenido valioso que encuentras en internet.

![Flutter](https://img.shields.io/badge/Flutter-3.38.9-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10.8-0175C2?style=flat&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-Drift-003B57?style=flat&logo=sqlite&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod-00BCD4?style=flat)
![Plataformas](https://img.shields.io/badge/Plataformas-Android%20%7C%20iOS-green?style=flat)

</div>

---

## ¿Qué es VerLink?

VerLink es una aplicacion de productividad personal que centraliza todo el contenido valioso que descubres mientras navegas en internet y redes sociales.

Cada dia consumes contenido en Instagram, YouTube, TikTok, LinkedIn, GitHub y decenas de sitios mas. El problema: lo pierdes. Guardas screenshots desordenados, envias links a tu propio chat, usas bookmarks que nunca vuelves a abrir.

**VerLink lo resuelve:** comparte cualquier link hacia VerLink desde el Share Sheet del sistema, y el contenido queda guardado con imagen preview, titulo, descripcion y plataforma de origen — listo para que lo encuentres cuando lo necesites.

> *"El lugar donde vive todo lo interesante que descubriste."*

---

## Caracteristicas del MVP (v1)

| Funcionalidad | Descripcion |
|---|---|
| **Captura via Share Sheet** | Guarda links desde cualquier app con un toque |
| **Metadata automatica** | Extrae titulo, descripcion e imagen preview del link |
| **Deteccion de plataforma** | Identifica YouTube, Instagram, TikTok, GitHub, y mas |
| **Favoritos** | Marca los links mas importantes para acceso rapido |
| **Prioridad** | Distingue contenido urgente del resto |
| **Tags personalizados** | Organiza por categorias con colores |
| **Busqueda full-text** | Encuentra cualquier link por titulo, descripcion, tags o plataforma |
| **Notificaciones** | Recordatorios de contenido prioritario pendiente |
| **100% offline** | Todo se guarda localmente, sin internet requerido |

---

## Stack Tecnologico

```
Flutter + Dart          Aplicacion multiplataforma (Android, iOS, Desktop, Web)
Drift + SQLite          Base de datos local embebida, sin servidor
Riverpod                Estado global reactivo
dio + html              Scraping de Open Graph metadata
cached_network_image    Cache local de imagenes preview
receive_sharing_intent  Captura de links via Share Sheet
flutter_local_notifs    Notificaciones locales
```

---

## Estructura del Proyecto

```
lib/
├── main.dart                          # Entry point
├── app/
│   └── app.dart                       # MaterialApp + navegacion principal
├── core/
│   ├── database/
│   │   ├── database.dart              # AppDatabase (Drift) + queries
│   │   ├── database.g.dart            # Codigo generado por Drift
│   │   └── tables/
│   │       ├── links_table.dart       # Tabla de links
│   │       ├── tags_table.dart        # Tabla de tags
│   │       └── link_tags_table.dart   # Relacion links <-> tags (N:N)
│   └── theme/
│       └── app_theme.dart             # Tema dark/light
└── features/
    ├── home/                          # Pantalla de inicio
    ├── saved/                         # Todos los links guardados
    ├── priority/                      # Links prioritarios
    ├── search/                        # Busqueda full-text
    ├── detail/                        # Detalle de un link
    └── capture/                       # Flujo de captura via Share Sheet
```

---

## Modelo de Datos

```
links
├── id, url, title, description
├── preview_image_url, preview_image_path
├── platform (youtube | instagram | tiktok | twitter | linkedin | github | web ...)
├── favicon_url
├── is_favorite, priority, is_read
├── remind_at, notes
└── created_at, updated_at

tags
├── id, name (unique), color
└── created_at

link_tags (relacion N:N)
├── link_id -> links.id
└── tag_id  -> tags.id
```

---

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.38.0
- Dart >= 3.10.0
- Android SDK (para build Android) o Xcode (para build iOS)

---

## Instalacion y ejecucion

### 1. Clonar el repositorio

```bash
git clone https://github.com/donaldoAndres1985/VerLink.git
cd VerLink
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Generar codigo de Drift

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Ejecutar la app

```bash
# En dispositivo o emulador conectado
flutter run

# Solo Android
flutter run -d android

# Solo iOS (requiere Mac + Xcode)
flutter run -d ios
```

---

## Plataformas soportadas

| Plataforma | Version | Estado |
|---|---|---|
| Android | 6.0+ (API 23+) | v1 — En desarrollo |
| iOS | 13.0+ | v1 — En desarrollo |
| Windows / macOS | — | v2 — Planificado |
| Web | — | v3 — Planificado |

---

## Roadmap

```
v1  Android + iOS
    Captura via Share Sheet
    Base de datos local (SQLite)
    Busqueda, favoritos, prioridad, tags, notificaciones

v2  Windows + macOS
    Clipboard watcher (detecta links copiados)
    Sincronizacion cloud
    Extension Chrome

v3  Web
    IA generativa: resumenes automaticos
    Busqueda semantica

v4  Second brain AI
    Clasificacion automatica
    Asistente inteligente de contenido
```

---

## Historias de Usuario

Todas las historias de usuario del MVP estan documentadas en la [Wiki del repositorio](https://github.com/donaldoAndres1985/VerLink/wiki/Historias-de-usuario).

22 HUs organizadas en 9 iteraciones de desarrollo.

---

## Issues y seguimiento

El desarrollo se gestiona mediante [GitHub Issues](https://github.com/donaldoAndres1985/VerLink/issues), una issue por cada historia de usuario, etiquetadas por iteracion.

---

## Autor

**Donaldo Andres Gandara Correa**
[donaldogandara@hotmail.com](mailto:donaldogandara@hotmail.com)

---

<div align="center">
Construido con Flutter — 2026
</div>
