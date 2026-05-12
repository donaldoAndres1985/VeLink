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
  String get openLinkTooltip => _s(es: 'Abrir enlace', en: 'Open link');
  String get linkMenuTooltip => _s(es: 'Más opciones', en: 'More options');
  String get favoriteSemantics => _s(es: 'Favorito', en: 'Favorite');

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
