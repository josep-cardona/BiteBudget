import 'package:BiteBudget/layout_scaffold.dart';
import 'package:BiteBudget/pages/home.dart';
import 'package:BiteBudget/pages/meal_plan_page.dart';
import 'package:BiteBudget/pages/shopping_list_page.dart';
import 'package:BiteBudget/pages/test_button_page.dart';
import 'package:BiteBudget/pages/welcome_page.dart';
import 'package:BiteBudget/pages/profile_page.dart';
import 'package:BiteBudget/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_gate.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.welcomePage,
  refreshListenable: AuthGate.instance,
  redirect: (context, state) {
    final loggedIn = AuthGate.instance.isLoggedIn;
    final current = state.uri.toString();
    final loggingIn = current == Routes.welcomePage ||
        current == '/login' ||
        current == '/register' ||
        current == '/user_info' ||
        current == '/meal_preferences';
    if (!loggedIn && !loggingIn) {
      // Not logged in, trying to access a protected page
      return Routes.welcomePage;
    }
    if (loggedIn && loggingIn) {
      // Already logged in, trying to access login/register
      return Routes.homePage;
    }
    return null;
  },
  routes: [
    GoRoute(path: Routes.welcomePage, builder: (context, state) => const WelcomePage()),
    GoRoute(path: Routes.buttonPage, builder: (context, state) => const TestButtonPage()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => LayoutScaffold(
        navigationShell: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.homePage,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.calendarPage,
              builder: (context, state) => const MealPlanPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shopPage,
              builder: (context, state) => const ShoppingListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profilePage,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ]
    )
  ],
);