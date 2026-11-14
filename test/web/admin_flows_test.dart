import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaku_frontend/domain/user.dart';
import 'package:yaku_frontend/infrastructure/auth_provider.dart';
import 'package:yaku_frontend/infrastructure/http_client.dart';
import 'package:yaku_frontend/presentation/pages/admin/equipment_page.dart';
import 'package:yaku_frontend/presentation/pages/admin/notifications_page.dart';
import 'package:yaku_frontend/presentation/pages/admin/ponds_page.dart';
import 'package:yaku_frontend/utils/token_storage.dart';

class TestAuth extends AuthProvider {
  @override
  User get user => const User(id: 7, username: 'test', firstName: 'Test',
      lastName: 'Admin', email: 'test@example.com', role: 'ADMIN');
}

class ApiStub implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int farmStatus = 200;
  List<dynamic> farms = [{'id': 1, 'ownerId': 7, 'name': 'Test farm'}];
  int notificationStatus = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancelFuture) async {
    requests.add(options);
    var status = 200;
    dynamic data = [];
    if (options.path == '/v1/farms') {
      status = farmStatus;
      data = farms;
    } else if (options.path.endsWith('/notifications')) {
      status = notificationStatus;
    } else if (options.method == 'POST') {
      status = 409;
      data = {'message': 'Duplicate device'};
    }
    return ResponseBody.fromString(jsonEncode(data), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ApiStub api;
  late HttpClientAdapter originalAdapter;
  late TestAuth auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    originalAdapter = httpClient.httpClientAdapter;
    api = ApiStub();
    httpClient.httpClientAdapter = api;
    auth = TestAuth();
  });
  tearDown(() {
    auth.dispose();
    httpClient.httpClientAdapter = originalAdapter;
  });

  Future<void> open(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
        value: auth, child: MaterialApp(home: page)));
    await tester.pumpAndSettle();
  }

  testWidgets('a farm access failure is visible and can be retried', (tester) async {
    api.farmStatus = 403;
    await open(tester, const PondsPage());
    expect(find.textContaining('No tienes acceso'), findsOneWidget);
    expect(find.text('No tienes estanques aún'), findsNothing);
    api.farmStatus = 200;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No tienes estanques aún'), findsOneWidget);
  });

  testWidgets('no farm shows guidance instead of an empty equipment list', (tester) async {
    api.farms = [];
    await open(tester, const EquipmentPage());
    expect(find.textContaining('No tienes una granja'), findsOneWidget);
    expect(api.requests.where((r) => r.path == '/v1/equipment'), isEmpty);
  });

  testWidgets('invalid pond volume never reaches the backend', (tester) async {
    await open(tester, const PondsPage());
    await tester.tap(find.text('Nuevo Estanque'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Estanque de prueba');
    await tester.enterText(find.byType(TextField).at(1), '-5');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(find.textContaining('volumen mayor que cero'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('a duplicate device keeps the form open and shows the conflict', (tester) async {
    await open(tester, const EquipmentPage());
    await tester.tap(find.text('Registrar Equipo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IOT NODE'));
    await tester.enterText(find.byType(TextField).at(0), 'Nodo prueba');
    await tester.enterText(find.byType(TextField).at(1), 'DEVICE-TEST');
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ya existe un registro'), findsOneWidget);
    expect(find.text('DEVICE-TEST'), findsOneWidget);
    expect(api.requests.last.path, '/v1/equipment/iot-device');
  });

  testWidgets('a notification error is not presented as no notifications', (tester) async {
    api.notificationStatus = 500;
    await open(tester, const NotificationsPage());
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Sin notificaciones'), findsNothing);
  });

  test('401 clears session keys, preserves other preferences and notifies auth', () async {
    SharedPreferences.setMockInitialValues({
      'yaku_access_token': 'old-token', 'yaku_user_id': 7, 'theme': 'dark',
    });
    api.farmStatus = 401;
    final invalidations = sessionInvalidations.value;
    await expectLater(httpClient.get('/v1/farms'), throwsA(isA<DioException>()));
    expect(await TokenStorage.getToken(), isNull);
    expect(sessionInvalidations.value, greaterThan(invalidations));
    expect(auth.error, contains('sesión venció'));
    expect((await SharedPreferences.getInstance()).getString('theme'), 'dark');
  });
}
