import 'dart:async';
import 'package:velink/features/capture/services/capture_service.dart';

class MockCaptureService implements CaptureService {
  final _controller = StreamController<String?>.broadcast();
  bool resetCalled = false;
  bool disposeCalled = false;

  @override
  Stream<String?> get urlStream => _controller.stream;

  @override
  Future<String?> getInitialUrl() async => null;

  @override
  void reset() => resetCalled = true;

  @override
  void dispose() {
    disposeCalled = true;
    _controller.close();
  }

  void emit(String url) => _controller.add(url);
}
