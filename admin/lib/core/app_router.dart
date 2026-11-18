import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/blocked_time_repository.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/service_repository.dart';
import '../ui/auth/not_authorized_view.dart';
import '../ui/auth/session_view_model.dart';
import '../ui/bookings/bookings_view.dart';
import '../ui/bookings/bookings_view_model.dart';
import '../ui/calendar/calendar_view.dart';
import '../ui/calendar/calendar_view_model.dart';
import '../ui/clients/client_detail_view.dart';
import '../ui/clients/client_detail_view_model.dart';
import '../ui/clients/clients_view.dart';
import '../ui/clients/clients_view_model.dart';
import '../ui/login/login_view.dart';
import '../ui/login/login_view_model.dart';
import '../ui/services/service_form_view.dart';
import '../ui/services/service_form_view_model.dart';
import '../ui/services/services_view.dart';
import '../ui/services/services_view_model.dart';
import '../ui/shell/app_shell.dart';
import '../ui/time_off/time_off_form_view.dart';
import '../ui/time_off/time_off_form_view_model.dart';
import '../ui/time_off/time_off_view.dart';
import '../ui/time_off/time_off_view_model.dart';

/// All route paths live here. Add new screens below.
class Routes {
  Routes._();
  static const splash = '/';
  static const login = '/login';
  static const notAuthorized = '/not-authorized';
  static const bookings = '/bookings';
  static const calendar = '/calendar';
  static const clients = '/clients';
  static String client(String id) => '/clients/$id';
  static const services = '/services';
  static const serviceNew = '/services/new';
  static String service(String id) => '/services/$id';
  static const timeOff = '/time-off';
  static const timeOffNew = '/time-off/new';
}

GoRouter createRouter(SessionViewModel session) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (context, state) {
      final at = state.matchedLocation;
      String? go(String target) => at == target ? null : target;
      switch (session.status) {
        case SessionStatus.loading:
          return go(Routes.splash);
        case SessionStatus.signedOut:
          return go(Routes.login);
        case SessionStatus.notAdmin:
          return go(Routes.notAuthorized);
        case SessionStatus.admin:
          final isGate = at == Routes.splash || at == Routes.login || at == Routes.notAuthorized;
          return isGate ? Routes.bookings : null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => ChangeNotifierProvider(
          create: (c) => LoginViewModel(c.read<AuthRepository>()),
          child: const LoginView(),
        ),
      ),
      GoRoute(
        path: Routes.notAuthorized,
        builder: (_, _) => const NotAuthorizedView(),
      ),
      // Signed-in area with bottom bar / side rail.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.bookings,
              builder: (_, _) => ChangeNotifierProvider(
                create: (c) => BookingsViewModel(c.read<BookingRepository>()),
                child: const BookingsView(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.calendar,
              builder: (_, _) => ChangeNotifierProvider(
                create: (c) => CalendarViewModel(c.read<BookingRepository>()),
                child: const CalendarView(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.clients,
              builder: (_, _) => ChangeNotifierProvider(
                create: (c) => ClientsViewModel(c.read<ClientRepository>()),
                child: const ClientsView(),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ChangeNotifierProvider(
                    create: (c) => ClientDetailViewModel(
                      c.read<ClientRepository>(),
                      c.read<BookingRepository>(),
                      state.pathParameters['id']!,
                    ),
                    child: const ClientDetailView(),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.services,
              builder: (_, _) => ChangeNotifierProvider(
                create: (c) => ServicesViewModel(c.read<ServiceRepository>()),
                child: const ServicesView(),
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, _) => ChangeNotifierProvider(
                    create: (c) => ServiceFormViewModel(c.read<ServiceRepository>(), null),
                    child: const ServiceFormView(),
                  ),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ChangeNotifierProvider(
                    create: (c) => ServiceFormViewModel(
                        c.read<ServiceRepository>(), state.pathParameters['id']),
                    child: const ServiceFormView(),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.timeOff,
              builder: (_, _) => ChangeNotifierProvider(
                create: (c) => TimeOffViewModel(c.read<BlockedTimeRepository>()),
                child: const TimeOffView(),
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, _) => ChangeNotifierProvider(
                    create: (c) => TimeOffFormViewModel(c.read<BlockedTimeRepository>()),
                    child: const TimeOffFormView(),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}
