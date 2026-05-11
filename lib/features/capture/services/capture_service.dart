import 'package:receive_sharing_intent/receive_sharing_intent.dart';

abstract class CaptureService {
  Stream<String?> get urlStream;
  Stream<String?> get titleStream;
  Future<String?> getInitialUrl();
  Future<String?> getInitialTitle();
  void reset();
  void dispose();
}

String? _extractUrl(List<SharedMediaFile> files) {
  final file = files
      .where((f) =>
          f.type == SharedMediaType.url || f.type == SharedMediaType.text)
      .firstOrNull;
  return file?.path;
}

String? _extractTitle(List<SharedMediaFile> files) {
  final file = files
      .where((f) =>
          f.type == SharedMediaType.url || f.type == SharedMediaType.text)
      .firstOrNull;
  final msg = file?.message?.trim();
  return (msg != null && msg.isNotEmpty) ? msg : null;
}

class ReceiveSharingIntentService implements CaptureService {
  @override
  Stream<String?> get urlStream =>
      ReceiveSharingIntent.instance.getMediaStream().map(_extractUrl);

  @override
  Stream<String?> get titleStream =>
      ReceiveSharingIntent.instance.getMediaStream().map(_extractTitle);

  @override
  Future<String?> getInitialUrl() async {
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    return _extractUrl(files);
  }

  @override
  Future<String?> getInitialTitle() async {
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    return _extractTitle(files);
  }

  @override
  void reset() => ReceiveSharingIntent.instance.reset();

  @override
  void dispose() {}
}
