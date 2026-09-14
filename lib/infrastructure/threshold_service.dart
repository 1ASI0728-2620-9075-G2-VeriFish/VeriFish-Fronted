import '../config/api_config.dart';
import '../domain/threshold.dart';
import 'http_client.dart';

Future<Threshold?> getThresholds(String species) async {
  try {
    final res = await httpClient.get(ApiEndpoints.thresholdsBySpecies(species));
    return Threshold.fromJson(res.data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

Future<Threshold> saveThresholds(Threshold threshold) async {
  final res = await httpClient.post(ApiEndpoints.thresholdsBase, data: threshold.toJson());
  return Threshold.fromJson(res.data as Map<String, dynamic>);
}
