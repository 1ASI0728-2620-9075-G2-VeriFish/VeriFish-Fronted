import '../config/api_config.dart';
import '../domain/plan.dart';
import '../domain/subscription.dart';
import 'http_client.dart';

Future<List<Plan>> getPlans() async {
  final res = await httpClient.get(ApiEndpoints.plansBase);
  final list = res.data as List? ?? [];
  return list.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
}

Future<Subscription?> getSubscription(int userId) async {
  try {
    final res = await httpClient.get(ApiEndpoints.subscriptionByUser(userId));
    if (res.data != null) {
      return Subscription.fromJson(res.data as Map<String, dynamic>);
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<String> checkoutSubscription({required int userId, required int planId}) async {
  final res = await httpClient.post(
    ApiEndpoints.subscriptionCheckout(userId),
    data: {'planId': planId},
  );
  return res.data['url']?.toString() ?? '';
}
