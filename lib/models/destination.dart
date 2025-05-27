import 'package:flutter/material.dart';


class Destination {
  const Destination({
    required this.label,
    required this.icon,
    this.color = Colors.black, // default color
  });

  final String label;
  final IconData icon;
  final Color color;
}



const destinations = [
  Destination(label: 'Home', icon: Icons.home, color: Color(0xff828282)),
  Destination(label: 'Calendar', icon: Icons.calendar_month,color: Color(0xff828282)),
  Destination(label: 'Shop', icon: Icons.shopping_cart,color: Color(0xff828282)),
  Destination(label: 'Profile', icon: Icons.person,color: Color(0xff828282)),
];