import 'package:flutter/material.dart';

/// Unified black button style for BiteBudget app.
final ButtonStyle biteBudgetBlackButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF2C2C2C),
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  elevation: 2,
  shadowColor: Colors.black45,
  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  textStyle: const TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    height: 1.4,
  ),
);
