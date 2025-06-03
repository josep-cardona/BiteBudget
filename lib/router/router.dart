import 'package:BiteBudget/layout_scaffold.dart';
import 'package:BiteBudget/pages/home.dart';
import 'package:BiteBudget/pages/meal_plan_page.dart';
import 'package:BiteBudget/pages/shopping_list_page.dart';
import 'package:BiteBudget/pages/test_button_page.dart';
import 'package:BiteBudget/pages/welcome_page.dart';
import 'package:BiteBudget/pages/profile_page.dart';
import 'package:BiteBudget/pages/user_info_form.dart';
import 'package:BiteBudget/pages/meal_preferences_form.dart';
import 'package:BiteBudget/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_gate.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.welcomePage,
  refreshListenable: AuthGate.instance,
  redirect: (context, state) async {
    final loggedIn = AuthGate.instance.isLoggedIn;
    final current = state.uri.toString();
    // Allow access to user info and meal preferences forms if not complete
    final isUserInfo = current == '/user_info';
    final isMealPrefs = current == '/meal_preferences';
    if (!loggedIn && !(current == Routes.welcomePage || current == '/login' || current == '/register')) {
      return Routes.welcomePage;
    }
    if (loggedIn) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return Routes.welcomePage;
      final appUser = await UserService().getUser(user.uid);
      if (appUser == null || appUser.name == null || appUser.surname == null) {
        if (!isUserInfo) return '/user_info';
      } else if (appUser.mealPreferencesCompleted != true) {
        if (!isMealPrefs) return '/meal_preferences';
      } else if (current == Routes.welcomePage || current == '/login' || current == '/register') {
        return Routes.homePage;
      }
    }
    return null;
  },
  routes: [
    GoRoute(path: Routes.welcomePage, builder: (context, state) => const WelcomePage()),
    GoRoute(path: Routes.buttonPage, builder: (context, state) => const TestButtonPage()),
    GoRoute(path: '/user_info', builder: (context, state) => const UserInfoForm()),
    GoRoute(path: '/meal_preferences', builder: (context, state) => const MealPreferencesForm()),
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