import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/client_repository.dart';
import 'data/repositories/blocked_time_repository.dart';
import 'data/repositories/service_repository.dart';
import 'ui/auth/session_view_model.dart';

/// Root: registers repositories and the session view model for the whole app.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => BookingRepository()),
        Provider(create: (_) => ClientRepository()),
        Provider(create: (_) => ServiceRepository()),
        Provider(create: (_) => BlockedTimeRepository()),
        ChangeNotifierProvider(
          create: (c) => SessionViewModel(c.read<AuthRepository>()),
        ),
      ],
      child: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late final GoRouter _router = createRouter(context.read<SessionViewModel>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Admin dashboard',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      routerConfig: _router,
    );
  }
}

ThemeData _theme() {
  const primary = Color(0xFF17645B);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
    scaffoldBackgroundColor: const Color(0xFFF7F8F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF172E2B),
      elevation: 0,
    ),
  );
}
