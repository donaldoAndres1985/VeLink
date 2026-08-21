import 'package:velink/features/capture/services/image_cache_service.dart';

class MockImageCacheService implements ImageCacheService {
  /// Ruta a devolver por defecto cuando no hay [onCache] ni [resultsByUrl].
  final String? result;

  /// Resultado específico por URL (tiene prioridad sobre [result]).
  final Map<String, String?> resultsByUrl;

  final List<String> requestedUrls = [];
  int callCount = 0;

  MockImageCacheService({this.result, this.resultsByUrl = const {}});

  @override
  Future<String?> cacheImage(String url) async {
    callCount++;
    requestedUrls.add(url);
    if (resultsByUrl.containsKey(url)) return resultsByUrl[url];
    return result;
  }
}
