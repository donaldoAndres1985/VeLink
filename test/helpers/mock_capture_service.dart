import 'dart:async';
import 'package:velink/features/capture/services/capture_service.dart';

class MockCaptureService implements CaptureService {
  final _urlController = StreamController<String?>.broadcast();
  final _titleController = StreamController<String?>.broadcast();
  bool resetCalled = false;
  bool disposeCalled = false;

  @override
  Stream<String?> get urlStream => _urlController.stream;

  @override
  Stream<String?> get titleStream => _titleController.stream;

  @override
  Future<String?> getInitialUrl() async => null;

  @override
  Future<String?> getInitialTitle() async => null;

  @override
  void reset() => resetCalled = true;

  @override
  void dispose() {
    disposeCalled = true;
    _urlController.close();
    _titleController.close();
  }

  void emit(String url) => _urlController.add(url);
  void emitTitle(String title) => _titleController.add(title);
}
