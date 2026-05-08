import 'package:velink/core/database/database.dart';

Link makeLink({
  int id = 1,
  required String url,
  String? title,
  String? description,
  String? previewImageUrl,
  String platform = 'web',
  bool isFavorite = false,
  int priority = 0,
  String? notes,
  DateTime? createdAt,
}) =>
    Link(
      id: id,
      url: url,
      title: title,
      description: description,
      previewImageUrl: previewImageUrl,
      previewImagePath: null,
      platform: platform,
      faviconUrl: null,
      isFavorite: isFavorite,
      priority: priority,
      isRead: false,
      remindAt: null,
      notes: notes,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
