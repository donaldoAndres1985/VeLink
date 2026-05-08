import 'package:flutter_test/flutter_test.dart';
import 'package:velink/features/capture/services/metadata_service.dart';

void main() {
  group('OgParser — extracción de metadatos', () {
    test('extrae og:title del HTML', () {
      const html = '<html><head>'
          '<meta property="og:title" content="Mi Titulo"/>'
          '</head></html>';
      final metadata = OgParser.parse(html);
      expect(metadata?.title, 'Mi Titulo');
    });

    test('extrae og:description del HTML', () {
      const html = '<html><head>'
          '<meta property="og:description" content="Una descripcion del link"/>'
          '</head></html>';
      final metadata = OgParser.parse(html);
      expect(metadata?.description, 'Una descripcion del link');
    });

    test('extrae og:image del HTML', () {
      const html = '<html><head>'
          '<meta property="og:image" content="https://example.com/img.jpg"/>'
          '</head></html>';
      final metadata = OgParser.parse(html);
      expect(metadata?.imageUrl, 'https://example.com/img.jpg');
    });

    test('usa <title> como fallback si no hay og:title', () {
      const html = '<html><head>'
          '<title>Titulo del documento</title>'
          '</head></html>';
      final metadata = OgParser.parse(html);
      expect(metadata?.title, 'Titulo del documento');
    });

    test('retorna null si no hay ningun metadato ni titulo', () {
      const html = '<html><head></head><body>Solo contenido</body></html>';
      final metadata = OgParser.parse(html);
      expect(metadata, equals(null));
    });

    test('extrae todos los campos OG a la vez', () {
      const html = '<html><head>'
          '<meta property="og:title" content="YouTube Video"/>'
          '<meta property="og:description" content="Un video increible"/>'
          '<meta property="og:image" content="https://i.ytimg.com/vi/abc/hq.jpg"/>'
          '</head></html>';
      final metadata = OgParser.parse(html);
      expect(metadata?.title, 'YouTube Video');
      expect(metadata?.description, 'Un video increible');
      expect(metadata?.imageUrl, 'https://i.ytimg.com/vi/abc/hq.jpg');
    });

    test('og:title tiene prioridad sobre <title>', () {
      const html = '<html><head>'
          '<title>Titulo del documento</title>'
          '<meta property="og:title" content="Titulo OG"/>'
          '</head></html>';
      final metadata = OgParser.parse(html);
      expect(metadata?.title, 'Titulo OG');
    });
  });
}
