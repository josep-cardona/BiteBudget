import 'package:bitebudget/layout_scaffold.dart';
import 'package:bitebudget/pages/home.dart';
import 'package:bitebudget/pages/meal_plan_page.dart';
import 'package:bitebudget/pages/shopping_list_page.dart';
import 'package:bitebudget/pages/test_button_page.dart';
import 'package:bitebudget/pages/welcome_page.dart';
import 'package:bitebudget/pages/profile_page.dart';
import 'package:bitebudget/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.welcomePage,
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