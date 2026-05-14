class AppStrings {
  final String _lang;

  AppStrings(String languageCode) : _lang = languageCode == 'en' ? 'en' : 'es';

  String _s({required String es, required String en}) => _lang == 'en' ? en : es;

  // ── Navigation ───────────────────────────────────────────────────────────
  String get navLinks => 'Links';
  String get navPending => _s(es: 'Pendientes', en: 'Pending');
  String get navTags => _s(es: 'Etiquetas', en: 'Labels');
  String get navSettings => _s(es: 'Ajustes', en: 'Settings');

  // ── Common ───────────────────────────────────────────────────────────────
  String get cancel => _s(es: 'Cancelar', en: 'Cancel');
  String get delete => _s(es: 'Eliminar', en: 'Delete');
  String get save => _s(es: 'Guardar', en: 'Save');
  String get create => _s(es: 'Crear', en: 'Create');
  String get noResults => _s(es: 'Sin resultados', en: 'No results');
  String get retry => _s(es: 'Reintentar', en: 'Retry');

  // ── Home ─────────────────────────────────────────────────────────────────
  String get homeTitle => 'VeLink';
  String get searchLinks => _s(es: 'Buscar links...', en: 'Search links...');
  String get filterAll => _s(es: 'Todos', en: 'All');
  String get filterFavorites => _s(es: 'Favoritos', en: 'Favorites');
  String get filterPlatform => _s(es: 'Filtrar', en: 'Filter');
  String get addLink => _s(es: 'Agregar link', en: 'Add link');
  String get noLinksYet => _s(es: 'No hay links guardados aún', en: 'No saved links yet');
  String get errorLoadLinks => _s(es: 'Error al cargar los links', en: 'Error loading links');
  String get errorSearch => _s(es: 'Error al buscar', en: 'Search error');
  String get filterByPlatform => _s(es: 'Filtrar por plataforma', en: 'Filter by platform');
  String get paste => _s(es: 'Pegar', en: 'Paste');
  String get go => _s(es: 'Ir', en: 'Go');
  String get platformAll => _s(es: 'Todas', en: 'All');

  // ── Pending ──────────────────────────────────────────────────────────────
  String get pendingTitle => _s(es: 'Pendientes', en: 'Pending');
  String get searchPending => _s(es: 'Buscar pendientes...', en: 'Search pending...');
  String get noPendingLinks => _s(es: 'No hay links pendientes', en: 'No pending links');
  String get noPendingDesc => _s(
    es: 'Los links que aún no has revisado aparecen aquí.',
    en: "Links you haven't reviewed yet will appear here.",
  );
  String get markReviewed => _s(es: 'Marcar revisado', en: 'Mark as reviewed');

  // ── Tags ─────────────────────────────────────────────────────────────────
  String get tagsTitle => _s(es: 'Etiquetas', en: 'Labels');
  String get noTagsYet => _s(es: 'No hay etiquetas aún', en: 'No labels yet');
  String get noTagsDesc => _s(
    es: 'Crea etiquetas para organizar tus links.',
    en: 'Create labels to organize your links.',
  );
  String get errorLoadTags => _s(es: 'Error al cargar etiquetas', en: 'Error loading labels');
  String get editTagTooltip => _s(es: 'Editar etiqueta', en: 'Edit label');
  String get deleteTagTitle => _s(es: 'Eliminar etiqueta', en: 'Delete label');
  String confirmDeleteTag(String name) => _s(
    es: '¿Eliminar la etiqueta "$name"?',
    en: 'Delete the label "$name"?',
  );
  String tagLinkCount(int count) => '$count link${count != 1 ? "s" : ""}';

  // ── Detail ───────────────────────────────────────────────────────────────
  String get detailTitle => _s(es: 'Detalle', en: 'Detail');
  String get noTitle => _s(es: 'Sin título', en: 'No title');
  String get tagsSection => _s(es: 'Etiquetas', en: 'Labels');
  String get noTagsAssigned => _s(es: 'Sin etiquetas', en: 'No labels');
  String get notesSection => _s(es: 'Notas', en: 'Notes');
  String get notesHint => _s(
    es: 'Escribe una nota sobre este link...',
    en: 'Write a note about this link...',
  );
  String get reminderSection => _s(es: 'Recordatorio', en: 'Reminder');
  String get noReminder => _s(es: 'Sin recordatorio configurado', en: 'No reminder set');
  String get addReminderLabel => _s(es: 'Agregar recordatorio', en: 'Add reminder');
  String get deleteReminderLabel => _s(es: 'Eliminar recordatorio', en: 'Delete reminder');
  String get openLink => _s(es: 'Abrir', en: 'Open');
  String get copyUrl => _s(es: 'Copiar', en: 'Copy');
  String get urlCopied => _s(es: 'URL copiada', en: 'URL copied');
  String savedOnDate(String platform, String date) => _s(
    es: '$platform · Guardado el $date',
    en: '$platform · Saved on $date',
  );
  List<String> get monthAbbrevs => _lang == 'en'
      ? const ['', 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
      : const ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  // ── Capture ──────────────────────────────────────────────────────────────
  String get captureTitle => _s(es: 'Guardar link', en: 'Save link');
  String get titleLabel => _s(es: 'Título', en: 'Title');
  String get titleHint => _s(es: 'Ingresa el título...', en: 'Enter title...');
  String get imageSection => _s(es: 'IMAGEN O CAPTURA', en: 'IMAGE OR SCREENSHOT');
  String get addImageHint => _s(es: 'Agregar imagen o screenshot', en: 'Add image or screenshot');
  String get gallery => _s(es: 'Galería', en: 'Gallery');
  String get camera => _s(es: 'Captura', en: 'Camera');
  String get changeImage => _s(es: 'Cambiar', en: 'Change');
  String get linkSectionLabel => 'LINK';
  String get newTagLabel => _s(es: 'Nuevo', en: 'New');
  String get createTagTitle => _s(es: 'Nuevo tag', en: 'New label');
  String get tagNameHint => _s(es: 'Nombre del tag', en: 'Label name');
  String get markFavorite => _s(es: 'Marcar como favorito', en: 'Mark as favorite');
  String get alreadySaved => _s(es: 'Este link ya está guardado', en: 'This link is already saved');
  String get errorLoadImage => _s(es: 'Error al cargar imagen', en: 'Error loading image');

  // ── Link Card ────────────────────────────────────────────────────────────
  String get removeFavorite => _s(es: 'Quitar favorito', en: 'Remove from favorites');
  String get addFavorite => _s(es: 'Marcar favorito', en: 'Add to favorites');
  String get markPending => _s(es: 'Marcar pendiente', en: 'Mark as pending');
  String get markReviewedAction => _s(es: 'Marcar revisado', en: 'Mark as reviewed');
  String get linkDeleted => _s(es: 'Link eliminado', en: 'Link deleted');
  String get removedFromFavorites => _s(es: 'Quitado de favoritos', en: 'Removed from favorites');
  String get markedAsFavorite => _s(es: 'Marcado como favorito', en: 'Marked as favorite');
  String get markedAsPending => _s(es: 'Marcado como pendiente', en: 'Marked as pending');
  String get markedAsReviewed => _s(es: 'Link marcado como revisado', en: 'Link marked as reviewed');
  String get undo => _s(es: 'Deshacer', en: 'Undo');
  String get openLinkTooltip => _s(es: 'Abrir enlace', en: 'Open link');
  String get linkMenuTooltip => _s(es: 'Más opciones para este link', en: 'More options for this link');
  String get favoriteSemantics => _s(es: 'Link favorito', en: 'Favorite link');
  String platformSemantics(String platform) => _s(es: 'Plataforma: $platform', en: 'Platform: $platform');

  // ── Collections ──────────────────────────────────────────────────────────
  String get navOrganize => _s(es: 'Organizar', en: 'Organize');
  String get tabCollections => _s(es: 'Colecciones', en: 'Collections');
  String get tabLabels => _s(es: 'Etiquetas', en: 'Labels');
  String get collectionsTitle => _s(es: 'Colecciones', en: 'Collections');
  String get noCollectionsYet => _s(es: 'No hay colecciones aún', en: 'No collections yet');
  String get noCollectionsDesc => _s(
    es: 'Crea colecciones para agrupar tus links.',
    en: 'Create collections to group your links.',
  );
  String get createCollection => _s(es: 'Nueva colección', en: 'New collection');
  String get editCollection => _s(es: 'Editar colección', en: 'Edit collection');
  String get deleteCollectionTitle => _s(es: 'Eliminar colección', en: 'Delete collection');
  String confirmDeleteCollection(String name) => _s(
    es: '¿Eliminar la colección "$name"? Los links no serán eliminados.',
    en: 'Delete the collection "$name"? Links will not be deleted.',
  );
  String get collectionNameLabel => _s(es: 'Nombre', en: 'Name');
  String get collectionNameHint => _s(es: 'Nombre de la colección', en: 'Collection name');
  String get collectionNameRequired => _s(es: 'El nombre es obligatorio', en: 'Name is required');
  String get collectionNameDuplicate => _s(es: 'Ya existe una colección con ese nombre', en: 'A collection with that name already exists');
  String get collectionDescLabel => _s(es: 'Descripción (opcional)', en: 'Description (optional)');
  String get collectionDescHint => _s(es: 'Describe esta colección...', en: 'Describe this collection...');
  String get collectionColorLabel => _s(es: 'Color', en: 'Color');
  String get collectionIconLabel => _s(es: 'Ícono', en: 'Icon');
  String get collectionInSection => _s(es: 'COLECCIONES', en: 'COLLECTIONS');
  String get noCollectionsAssigned => _s(es: 'Sin colecciones', en: 'No collections');
  String get removeFromCollection => _s(es: 'Quitar de colección', en: 'Remove from collection');
  String get linkRemovedFromCollection => _s(es: 'Link removido de la colección', en: 'Link removed from collection');
  String collectionLinkCount(int count) => _s(
    es: '$count link${count != 1 ? "s" : ""}',
    en: '$count link${count != 1 ? "s" : ""}',
  );
  String get searchInCollection => _s(es: 'Buscar en colección...', en: 'Search in collection...');
  String get noLinksInCollection => _s(es: 'No hay links en esta colección', en: 'No links in this collection');
  String get noLinksInCollectionDesc => _s(
    es: 'Agrega links a esta colección desde la pantalla de captura.',
    en: 'Add links to this collection from the capture screen.',
  );
  String get errorLoadCollections => _s(es: 'Error al cargar colecciones', en: 'Error loading collections');

  // ── Settings ─────────────────────────────────────────────────────────────
  String get settingsTitle => _s(es: 'Ajustes', en: 'Settings');
  String get settingsLanguage => _s(es: 'Idioma', en: 'Language');
  String get settingsNotifications => _s(es: 'Notificaciones', en: 'Notifications');
  String get settingsAppInfo => _s(es: 'Información de la app', en: 'App info');
  String get languageSpanish => 'Español';
  String get languageEnglish => 'English';
  String get notificationsEnabledMsg => _s(es: 'Notificaciones activadas', en: 'Notifications enabled');
  String get notificationsDisabledMsg => _s(es: 'Notificaciones desactivadas', en: 'Notifications disabled');
  String get appVersion => _s(es: 'Versión', en: 'Version');
  String get appDescription => _s(
    es: 'Tu segunda memoria digital.\nGuarda, organiza y redescubre links.',
    en: 'Your second digital memory.\nSave, organize and rediscover links.',
  );

  // ── Notifications ────────────────────────────────────────────────────────
  String get notifFavoritesTitle => _s(es: 'Links favoritos', en: 'Favorite links');
  String notifFavoritesBody(int count) => _s(
    es: 'Tienes $count link${count != 1 ? "s" : ""} favorito${count != 1 ? "s" : ""} pendiente${count != 1 ? "s" : ""} de revisar',
    en: 'You have $count pending favorite link${count != 1 ? "s" : ""} to review',
  );
  String get notifChannelFavorites => _s(es: 'Favoritos', en: 'Favorites');
  String get notifChannelReminders => _s(es: 'Recordatorios', en: 'Reminders');
  String notifReminderTitle(String linkTitle) => _s(
    es: 'Recordatorio: $linkTitle',
    en: 'Reminder: $linkTitle',
  );
  String get notifReminderBody => _s(
    es: 'Tienes un link guardado para revisar',
    en: 'You have a saved link to review',
  );

  // ── Legal & Data ─────────────────────────────────────────────────────────
  String get settingsLegal => _s(es: 'Legal', en: 'Legal');
  String get settingsDataSection => _s(es: 'Cuenta y datos', en: 'Account & data');
  String get privacyPolicyTitle => _s(es: 'Política de privacidad', en: 'Privacy Policy');
  String get termsTitle => _s(es: 'Términos de uso', en: 'Terms of Use');
  String get settingsDeleteMyData => _s(es: 'Eliminar mis datos', en: 'Delete my data');
  String get settingsContactSupport => _s(es: 'Contactar soporte', en: 'Contact support');
  String get settingsExportData => _s(es: 'Exportar datos', en: 'Export data');
  String get settingsExportDataSubtitle => _s(es: 'Guarda un respaldo JSON de todos tus datos', en: 'Save a JSON backup of all your data');
  String get settingsImportData => _s(es: 'Importar datos', en: 'Import data');
  String get settingsImportDataSubtitle => _s(es: 'Restaura links desde un archivo de respaldo', en: 'Restore links from a backup file');
  String get settingsExportError => _s(es: 'No se pudo exportar el respaldo.', en: 'Could not export backup.');
  String get importFileNotFound => _s(es: 'Archivo de respaldo inválido o no compatible.', en: 'Invalid or incompatible backup file.');
  String get importInvalidFile => _s(es: 'Archivo de respaldo inválido.', en: 'Invalid backup file.');
  String importPreviewMsg(int links, int tags, int colls) => _s(
    es: '$links links, $tags etiquetas, $colls colecciones. Se combinarán con los datos actuales.',
    en: '$links links, $tags labels, $colls collections. Will be merged with current data.',
  );
  String importSuccessMsg(int imported, int skipped) => _s(
    es: 'Importación completada: $imported links importados, $skipped duplicados omitidos.',
    en: 'Import completed: $imported links imported, $skipped duplicates skipped.',
  );
  String get importConfirm => _s(es: 'Importar', en: 'Import');
  String get notificationsSubtitle => _s(es: 'Recibir recordatorios y actualizaciones', en: 'Receive reminders and updates');
  String get notificationsStatusEnabled => _s(es: 'Las notificaciones están activadas. Recibirás recordatorios y actualizaciones.', en: 'Notifications are enabled. You will receive reminders and updates.');
  String get notificationsStatusDisabled => _s(es: 'Las notificaciones están desactivadas.', en: 'Notifications are disabled.');
  String get privacyPolicySubtitle => _s(es: 'Conoce cómo protegemos tus datos', en: 'Learn how we protect your data');
  String get termsSubtitle => _s(es: 'Lee nuestros términos y condiciones', en: 'Read our terms and conditions');
  String get deleteMyDataSubtitle => _s(es: 'Elimina permanentemente todos tus datos', en: 'Permanently delete all your data');
  String get contactSupportSubtitle => _s(es: 'Obtén ayuda o envíanos un mensaje', en: 'Get help or send us a message');
  String get deleteDataWarning => _s(
    es: 'Esta acción eliminará permanentemente todos tus links, etiquetas, colecciones, notas y recordatorios.\n\nEsta acción no se puede deshacer.',
    en: 'This action will permanently delete all your links, labels, collections, notes and reminders.\n\nThis action cannot be undone.',
  );
  String get deleteDataConfirm => _s(es: 'Eliminar todo', en: 'Delete all');
  String get deleteDataSuccess => _s(es: 'Todos los datos han sido eliminados', en: 'All data has been deleted');
  String get notifPermissionBlocked => _s(
    es: 'Las notificaciones están desactivadas en la configuración del sistema.',
    en: 'Notifications are disabled in system settings.',
  );
  String get privacyPolicyBody => _lang == 'en' ? _kPrivacyEn : _kPrivacyEs;
  String get termsBody => _lang == 'en' ? _kTermsEn : _kTermsEs;

  // ── Time Ago ─────────────────────────────────────────────────────────────
  String timeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) {
      final y = (diff.inDays / 365).floor();
      return _s(
        es: 'Hace $y año${y > 1 ? "s" : ""}',
        en: '$y year${y > 1 ? "s" : ""} ago',
      );
    }
    if (diff.inDays >= 30) {
      final m = (diff.inDays / 30).floor();
      return _s(
        es: 'Hace $m mes${m > 1 ? "es" : ""}',
        en: '$m month${m > 1 ? "s" : ""} ago',
      );
    }
    if (diff.inDays > 0) {
      return _s(
        es: 'Hace ${diff.inDays} día${diff.inDays > 1 ? "s" : ""}',
        en: '${diff.inDays} day${diff.inDays > 1 ? "s" : ""} ago',
      );
    }
    if (diff.inHours > 0) {
      return _s(
        es: 'Hace ${diff.inHours} hora${diff.inHours > 1 ? "s" : ""}',
        en: '${diff.inHours} hour${diff.inHours > 1 ? "s" : ""} ago',
      );
    }
    if (diff.inMinutes > 0) {
      return _s(
        es: 'Hace ${diff.inMinutes} min',
        en: '${diff.inMinutes} min ago',
      );
    }
    return _s(es: 'Ahora', en: 'Just now');
  }
}

const _kPrivacyEs = '''
POLÍTICA DE PRIVACIDAD — VeLink
Última actualización: mayo 2026

1. INFORMACIÓN QUE ALMACENAMOS
VeLink almacena localmente en tu dispositivo:
• Links guardados y sus metadatos (título, descripción, URL, plataforma)
• Imágenes y capturas de pantalla agregadas manualmente
• Notas y recordatorios asociados a links
• Etiquetas y colecciones creadas por ti
• Preferencias de idioma y notificaciones

2. ACCESO AL DISPOSITIVO
• Portapapeles: accedemos al portapapeles solo cuando tocas el botón + o "Pegar", para detectar URLs automáticamente. No leemos el portapapeles en segundo plano.
• Cámara y galería: solo cuando lo solicitas explícitamente al agregar una imagen a un link.
• Notificaciones: para recordatorios y alertas de links favoritos, únicamente si activas las notificaciones.

3. ALMACENAMIENTO Y PRIVACIDAD
• Todos los datos se almacenan localmente en tu dispositivo.
• VeLink no cuenta con servidores propios ni envía datos a la nube.
• Las imágenes de preview se obtienen de URLs externas (Open Graph) y se cargan bajo demanda; dichas URLs están sujetas a la política de privacidad de cada sitio.

4. ANALYTICS Y LOGS DE ERRORES
VeLink no recopila datos de uso, analytics ni logs de errores de forma automática.

5. MENORES DE EDAD
VeLink no está dirigida a menores de 13 años. Si eres menor de 13 años, no uses esta aplicación.

6. ELIMINACIÓN DE DATOS
Puedes eliminar todos tus datos locales desde Ajustes > Eliminar mis datos. Esta acción es permanente e irreversible.

7. CONTACTO
Para consultas sobre privacidad: soporte@velink.app
''';

const _kPrivacyEn = '''
PRIVACY POLICY — VeLink
Last updated: May 2026

1. INFORMATION WE STORE
VeLink stores locally on your device:
• Saved links and their metadata (title, description, URL, platform)
• Images and screenshots added manually by you
• Notes and reminders associated with links
• Labels and collections you create
• Language and notification preferences

2. DEVICE ACCESS
• Clipboard: we access the clipboard only when you tap the + button or "Paste", to detect URLs automatically. We do not read the clipboard in the background.
• Camera and gallery: only when you explicitly request it when adding an image to a link.
• Notifications: for reminders and favorite link alerts, only if you enable notifications.

3. STORAGE AND PRIVACY
• All data is stored locally on your device.
• VeLink has no servers and does not send data to the cloud.
• Preview images are fetched from external URLs (Open Graph) on demand; those URLs are subject to the privacy policy of each respective site.

4. ANALYTICS AND CRASH LOGS
VeLink does not automatically collect usage data, analytics, or crash logs.

5. CHILDREN
VeLink is not directed at children under 13. If you are under 13, do not use this application.

6. DATA DELETION
You can delete all your local data from Settings > Delete my data. This action is permanent and irreversible.

7. CONTACT
For privacy inquiries: soporte@velink.app
''';

const _kTermsEs = '''
TÉRMINOS DE USO — VeLink
Última actualización: mayo 2026

1. USO PERMITIDO
VeLink es una aplicación para guardar y organizar links personales. El usuario es el único responsable del contenido que guarda en la aplicación y del uso que hace de los links almacenados.

2. CONTENIDO EXTERNO
VeLink no controla, modera ni es responsable del contenido de los links externos guardados. Los metadatos (título, descripción, imagen) se obtienen de sitios de terceros; VeLink no garantiza su exactitud ni disponibilidad.

3. LIMITACIÓN DE RESPONSABILIDAD
VeLink se proporciona "tal cual", sin garantías de ningún tipo. El desarrollador no se hace responsable de pérdida de datos, daños o cualquier perjuicio derivado del uso de la aplicación.

4. MODIFICACIONES
Podemos actualizar estos términos en cualquier momento. El uso continuado de la aplicación implica la aceptación de los términos actualizados.

5. CONTACTO
soporte@velink.app
''';

const _kTermsEn = '''
TERMS OF USE — VeLink
Last updated: May 2026

1. PERMITTED USE
VeLink is an application for saving and organizing personal links. The user is solely responsible for the content saved in the application and for the use made of stored links.

2. EXTERNAL CONTENT
VeLink does not control, moderate, or take responsibility for the content of saved external links. Metadata (title, description, image) is fetched from third-party sites; VeLink does not guarantee its accuracy or availability.

3. LIMITATION OF LIABILITY
VeLink is provided "as is" without warranties of any kind. The developer is not liable for data loss, damages, or any harm resulting from the use of the application.

4. CHANGES
We may update these terms at any time. Continued use of the application implies acceptance of the updated terms.

5. CONTACT
soporte@velink.app
''';
