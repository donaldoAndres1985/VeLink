import 'package:velink/features/capture/models/og_metadata.dart';
import 'package:velink/features/capture/services/metadata_service.dart';

class MockMetadataService implements MetadataService {
  final OgMetadata? result;
  int callCount = 0;

  MockMetadataService({this.result});

  @override
  Future<OgMetadata?> fetchMetadata(String url) async {
    callCount++;
    return result;
  }
}
