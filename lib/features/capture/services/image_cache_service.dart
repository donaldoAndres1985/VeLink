import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Descarga y persiste localmente una imagen remota (ej. el `og:image` de un
/// link capturado). Muchas CDNs (Facebook, Instagram, LinkedIn...) sirven esa
/// imagen desde una URL firmada con expiración corta (días, no meses): sin
/// una copia local, la preview del link se rompe permanentemente en cuanto
/// esa URL vence, aunque el link en sí siga siendo válido.
abstract class ImageCacheService {
  /// Intenta descargar [url] y guardarla en almacenamiento local del app.
  /// Devuelve la ruta local si tuvo éxito, o `null` si falla por cualquier
  /// motivo (sin conexión, URL inválida, timeout, etc.) — nunca lanza,
  /// para que el caller pueda seguir usando la URL remota como respaldo.
  Future<String?> cacheImage(String url);
}

class ImageCacheServiceImpl implements ImageCacheService {
  final Dio _dio;

  ImageCacheServiceImpl([Dio? dio]) : _dio = dio ?? Dio();

  @override
  Future<String?> cacheImage(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final previewsDir = Directory(p.join(dir.path, 'link_previews'));
      if (!await previewsDir.exists()) {
        await previewsDir.create(recursive: true);
      }

      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}${_extensionFor(url)}';
      final file = File(p.join(previewsDir.path, fileName));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _extensionFor(String url) {
    final uriPath = Uri.tryParse(url)?.path ?? '';
    final ext = p.extension(uriPath);
    if (ext.isEmpty || ext.length > 5) return '.jpg';
    return ext;
  }
}

final imageCacheServiceProvider = Provider<ImageCacheService>((ref) {
  return ImageCacheServiceImpl();
});
