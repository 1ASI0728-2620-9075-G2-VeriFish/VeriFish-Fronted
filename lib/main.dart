import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'infrastructure/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  final auth = AuthProvider();
  await auth.tryRestoreSession();
  runApp(YakuApp(auth: auth));
}

class YakuApp extends StatelessWidget {
  final AuthProvider auth;
  const YakuApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: auth,
      child: Builder(
        builder: (context) {
          final router = buildRouter(context.read<AuthProvider>());
          return MaterialApp.router(
            title: 'YakuControl',
            theme: buildTheme(),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
