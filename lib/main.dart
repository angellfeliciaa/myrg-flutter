import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/myrg_api.dart';
import 'core/router/app_router.dart';
import 'core/session/session_store.dart';
import 'features/auth/data/auth_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SessionStore.load();
  MyrgApi.onSessionEnded = (reason) {
    AuthApi.clearLocalData();
    AppRouter.router.go(AppRoutes.login);
    appMessenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(reason.message)));
  };
  runApp(const ProviderScope(child: MyRgApp()));
}
