import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/og_metadata.dart';

abstract class MetadataService {
  Future<OgMetadata?> fetchMetadata(String url);
}

class OgParser {
  static OgMetadata? parse(String htmlContent, {String? baseUrl}) {
    final document = html_parser.parse(htmlContent);

    String? getMetaContent(String property) {
      return document
          .querySelectorAll('meta')
          .where((el) =>
              el.attributes['property'] == property ||
              el.attributes['name'] == property)
          .firstOrNull
          ?.attributes['content'];
    }

    final title = getMetaContent('og:title') ??
        document.querySelector('title')?.text.trim();
    final description = getMetaContent('og:description');
    var imageUrl = getMetaContent('og:image');

    // Resolve protocol-relative and relative og:image URLs to absolute HTTPS
    if (imageUrl != null) {
      if (imageUrl.startsWith('//')) {
        imageUrl = 'https:$imageUrl';
      } else if (imageUrl.startsWith('/') && baseUrl != null) {
        final base = Uri.tryParse(baseUrl);
        if (base != null) {
          imageUrl = '${base.scheme}://${base.host}$imageUrl';
        }
      }
    }

    if (title == null && description == null && imageUrl == null) return null;

    return OgMetadata(title: title, description: description, imageUrl: imageUrl);
  }
}

class DioMetadataService implements MetadataService {
  final Dio _dio;

  DioMetadataService([Dio? dio]) : _dio = dio ?? Dio();

  @override
  Future<OgMetadata?> fetchMetadata(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; VerLink/1.0; +https://verlink.app)',
          },
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 12),
        ),
      );
      if (response.data == null) return null;
      return OgParser.parse(response.data!, baseUrl: url);
    } catch (_) {
      return null;
    }
  }
}
