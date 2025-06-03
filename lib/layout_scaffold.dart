import 'package:BiteBudget/models/destination.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LayoutScaffold extends StatelessWidget{

  const LayoutScaffold({
    required this.navigationShell,
    Key? key}):super(key: key?? const ValueKey<String>('LayoutScaffold'));
  
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey, // subtle gray color
            width: 0.5,         // very thin border
          ),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.transparent,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
          destinations: destinations.map(
            (destination) => NavigationDestination(
              icon: Icon(destination.icon, color: destination.color),
              selectedIcon: Icon(destination.icon, color: Colors.black),
              label: destination.label,
            ),
          ).toList(),
        ),
      ),
    ),
  );
}