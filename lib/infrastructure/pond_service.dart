import '../config/api_config.dart';
import '../domain/pond.dart';
import 'http_client.dart';

Future<List<Pond>> getPondsByFarm(int farmId) async {
  final res = await httpClient.get(ApiEndpoints.pondsByFarm(farmId));
  final list = res.data as List? ?? [];
  return list.map((e) => Pond.fromJson(e as Map<String, dynamic>)).toList();
}

Future<List<Pond>> getPondsByOperator(int operatorId) async {
  final res = await httpClient.get(ApiEndpoints.pondsByOperator(operatorId));
  final list = res.data as List? ?? [];
  return list.map((e) => Pond.fromJson(e as Map<String, dynamic>)).toList();
}

Future<Pond> getPond(int id) async {
  final res = await httpClient.get(ApiEndpoints.pondById(id));
  return Pond.fromJson(res.data as Map<String, dynamic>);
}

Future<Pond> createPond({required int farmId, required String name, required String species, required double volume}) async {
  final res = await httpClient.post(ApiEndpoints.pondsBase, data: {'farmId': farmId, 'name': name, 'species': species, 'volume': volume});
  return Pond.fromJson(res.data as Map<String, dynamic>);
}

Future<Pond> updatePond(int id, {required String name, required String species, required double volume}) async {
  final res = await httpClient.put(ApiEndpoints.pondById(id), data: {'name': name, 'species': species, 'volume': volume});
  return Pond.fromJson(res.data as Map<String, dynamic>);
}

Future<List<SensorReading>> getTelemetryStatus(int pondId) async {
  try {
    final res = await httpClient.get(ApiEndpoints.telemetryStatus(pondId));
    final list = res.data as List? ?? [];
    return list.map((e) => SensorReading.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) { return []; }
}

Future<List<HistoricalReading>> getTelemetryHistorical(int pondId) async {
  try {
    final res = await httpClient.get(ApiEndpoints.telemetryHistorical(pondId));
    final list = res.data as List? ?? [];
    return list.map((e) => HistoricalReading.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) { return []; }
}

Future<void> ingestReading({required int sensorId, required int pondId, required String sensorType, required double value, required String unit}) async {
  await httpClient.post(ApiEndpoints.telemetryIngest, data: {
    'sensorId': sensorId, 'pondId': pondId, 'sensorType': sensorType,
    'value': value, 'unit': unit, 'timestamp': DateTime.now().toIso8601String(),
  });
}

Future<Pond> assignOperatorToPond(int pondId, int operatorId) async {
  final res = await httpClient.post(ApiEndpoints.pondAssign(pondId), data: {'operatorId': operatorId});
  return Pond.fromJson(res.data as Map<String, dynamic>);
}

Future<Pond> deassignOperatorFromPond(int pondId, int operatorId) async {
  final res = await httpClient.delete(ApiEndpoints.pondDeassign(pondId, operatorId));
  return Pond.fromJson(res.data as Map<String, dynamic>);
}

Future<List<Map<String, dynamic>>> getOperators() async {
  final res = await httpClient.get(ApiEndpoints.usersBase);
  final list = res.data as List? ?? [];
  return list
      .map((e) => e as Map<String, dynamic>)
      .where((u) {
        final roles = u['roles'];
        return roles is List && roles.contains('OPERATOR');
      })
      .toList();
}
