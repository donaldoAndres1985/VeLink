import 'package:receive_sharing_intent/receive_sharing_intent.dart';

abstract class CaptureService {
  Stream<String?> get urlStream;
  Future<String?> getInitialUrl();
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

class ReceiveSharingIntentService implements CaptureService {
  @override
  Stream<String?> get urlStream =>
      ReceiveSharingIntent.instance.getMediaStream().map(_extractUrl);

  @override
  Future<String?> getInitialUrl() async {
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    return _extractUrl(files);
  }

  @override
  void reset() => ReceiveSharingIntent.instance.reset();

  @override
  void dispose() {}
}
