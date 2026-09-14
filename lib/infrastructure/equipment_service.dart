import '../config/api_config.dart';
import '../domain/equipment.dart';
import 'http_client.dart';

Future<List<Equipment>> getEquipment({int? farmId}) async {
  final res = await httpClient.get(ApiEndpoints.equipmentBase, queryParameters: farmId != null ? {'farmId': farmId} : null);
  final list = res.data as List? ?? [];
  return list.map((e) => Equipment.fromJson(e as Map<String, dynamic>)).toList();
}

Future<Equipment> createEquipment({required int farmId, required String type, required String name, required String physicalCode}) async {
  final res = await httpClient.post(ApiEndpoints.equipmentBase, data: {'farmId': farmId, 'type': type, 'name': name, 'physicalCode': physicalCode});
  return Equipment.fromJson(res.data as Map<String, dynamic>);
}

Future<List<Equipment>> createIoTDevice({required int farmId, required String name, required String physicalCode}) async {
  final res = await httpClient.post('${ApiEndpoints.equipmentBase}/iot-device', data: {'farmId': farmId, 'deviceName': name, 'deviceId': physicalCode});
  final list = res.data as List? ?? [];
  return list.map((e) => Equipment.fromJson(e as Map<String, dynamic>)).toList();
}

Future<void> deleteEquipment(int id) async {
  await httpClient.delete(ApiEndpoints.equipmentById(id));
}

Future<Equipment> linkEquipment(int equipmentId, int pondId) async {
  final res = await httpClient.post(ApiEndpoints.equipmentLink(equipmentId, pondId));
  return Equipment.fromJson(res.data as Map<String, dynamic>);
}

Future<void> activateActuator(int equipmentId) async {
  await httpClient.post(ApiEndpoints.equipmentCommand(equipmentId));
}
