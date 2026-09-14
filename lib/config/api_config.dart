import 'package:yaku_frontend/config/environment.dart';

final String apiBaseUrl = Environment.baseUrl;

class ApiEndpoints {
  static const signin = '/v1/users/signin';
  static const signup = '/v1/users/signup';
  static const usersBase = '/v1/users';
  static const usersByUsername = '/v1/users/by-username';
  static const farmsBase = '/v1/farms';
  static const pondsBase = '/v1/ponds';
  static const equipmentBase = '/v1/equipment';
  static const plansBase = '/v1/plans';
  static const telemetryIngest = '/v1/telemetry/manual-ingest';

  static String notifications(int userId) => '/v1/users/$userId/notifications';
  static String markNotificationsRead(int userId) => '/v1/users/$userId/notifications/read';
  static String changePassword(int userId) => '/v1/users/$userId/password';
  static String deviceTokens(int userId) => '/v1/users/$userId/device-tokens';
  static String userById(int id) => '/v1/users/$id';
  static String farmById(int id) => '/v1/farms/$id';
  static String createFarmToken(int farmId) => '/v1/iam/farms/$farmId/tokens';
  static String pondsByFarm(int farmId) => '/v1/ponds/farm/$farmId';
  static String pondsByOperator(int operatorId) => '/v1/ponds/operator/$operatorId';
  static String pondById(int id) => '/v1/ponds/$id';
  static String pondAssign(int pondId) => '/v1/ponds/$pondId/assignments';
  static String pondDeassign(int pondId, int operatorId) => '/v1/ponds/$pondId/deassignments/$operatorId';
  static String telemetryStatus(int pondId) => '/v1/telemetry/ponds/$pondId/status';
  static String telemetryHistorical(int pondId) => '/v1/telemetry/ponds/$pondId/historical';
  static String equipmentById(int id) => '/v1/equipment/$id';
  static String equipmentLink(int equipmentId, int pondId) => '/v1/equipment/$equipmentId/link/$pondId';
  static String equipmentCommand(int equipmentId) => '/v1/equipment/$equipmentId/command';
  static String subscriptionByUser(int userId) => '/v1/subscriptions/$userId';
  static String subscriptionCheckout(int userId) => '/v1/subscriptions/$userId/checkout';
  static String usersByFarm(int farmId) => '/v1/users?farmId=$farmId';

  static const thresholdsBase = '/v1/telemetry/thresholds';
  static String thresholdsBySpecies(String species) => '/v1/telemetry/thresholds/$species';
}
