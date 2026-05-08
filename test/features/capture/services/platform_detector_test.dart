import 'package:flutter_test/flutter_test.dart';
import 'package:velink/features/capture/services/platform_detector.dart';

void main() {
  group('PlatformDetector — plataformas reconocidas', () {
    test('detecta youtube.com', () {
      expect(PlatformDetector.detect('https://youtube.com/watch?v=abc'), AppPlatform.youtube);
    });

    test('detecta youtu.be (URL corta)', () {
      expect(PlatformDetector.detect('https://youtu.be/abc123'), AppPlatform.youtube);
    });

    test('detecta m.youtube.com (subdominio movil)', () {
      expect(PlatformDetector.detect('https://m.youtube.com/watch?v=abc'), AppPlatform.youtube);
    });

    test('detecta instagram.com', () {
      expect(PlatformDetector.detect('https://www.instagram.com/p/abc123'), AppPlatform.instagram);
    });

    test('detecta tiktok.com', () {
      expect(PlatformDetector.detect('https://www.tiktok.com/@user/video/123'), AppPlatform.tiktok);
    });

    test('detecta twitter.com', () {
      expect(PlatformDetector.detect('https://twitter.com/user/status/123'), AppPlatform.twitter);
    });

    test('detecta x.com como twitter', () {
      expect(PlatformDetector.detect('https://x.com/user/status/123'), AppPlatform.twitter);
    });

    test('detecta linkedin.com', () {
      expect(PlatformDetector.detect('https://www.linkedin.com/in/usuario'), AppPlatform.linkedin);
    });

    test('detecta facebook.com', () {
      expect(PlatformDetector.detect('https://www.facebook.com/video/123'), AppPlatform.facebook);
    });

    test('detecta reddit.com', () {
      expect(PlatformDetector.detect('https://www.reddit.com/r/flutter/'), AppPlatform.reddit);
    });

    test('detecta github.com', () {
      expect(PlatformDetector.detect('https://github.com/flutter/flutter'), AppPlatform.github);
    });

    test('detecta pages en github.io como github', () {
      expect(PlatformDetector.detect('https://user.github.io/repo'), AppPlatform.github);
    });

    test('detecta medium.com', () {
      expect(PlatformDetector.detect('https://medium.com/@autor/articulo'), AppPlatform.medium);
    });

    test('detecta publicaciones en subdominio de medium', () {
      expect(PlatformDetector.detect('https://blog.medium.com/articulo'), AppPlatform.medium);
    });
  });

  group('PlatformDetector — casos borde', () {
    test('URL desconocida retorna web', () {
      expect(PlatformDetector.detect('https://example.com/page'), AppPlatform.web);
    });

    test('URL con www. es detectada correctamente', () {
      expect(PlatformDetector.detect('https://www.youtube.com/watch?v=abc'), AppPlatform.youtube);
    });

    test('URL invalida retorna web', () {
      expect(PlatformDetector.detect('no-es-una-url'), AppPlatform.web);
    });

    test('URL vacia retorna web', () {
      expect(PlatformDetector.detect(''), AppPlatform.web);
    });
  });

  group('PlatformInfo — informacion de cada plataforma', () {
    test('YouTube tiene label y color correctos', () {
      final info = PlatformInfo.forPlatform(AppPlatform.youtube);
      expect(info.label, 'YouTube');
      expect(info.color.value, 0xFFFF0000);
    });

    test('web tiene label "Web"', () {
      final info = PlatformInfo.forPlatform(AppPlatform.web);
      expect(info.label, 'Web');
    });

    test('todas las plataformas tienen label, color e icono no nulos', () {
      for (final platform in AppPlatform.values) {
        final info = PlatformInfo.forPlatform(platform);
        expect(info.label, isNotEmpty);
        expect(info.icon, isNotNull);
      }
    });
  });
}
