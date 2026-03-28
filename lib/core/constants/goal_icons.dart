import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GoalIconOption {
  const GoalIconOption({
    required this.key,
    required this.icon,
    required this.color,
  });

  final String key;
  final IconData icon;
  final Color color;
}

abstract final class GoalIcons {
  static const all = [
    GoalIconOption(
      key: 'flag',
      icon: LucideIcons.flag,
      color: Color(0xFF9C7CFF),
    ),
    GoalIconOption(
      key: 'laptop',
      icon: LucideIcons.laptop2,
      color: Color(0xFF00E5BF),
    ),
    GoalIconOption(
      key: 'plane',
      icon: LucideIcons.plane,
      color: Color(0xFF60A5FA),
    ),
    GoalIconOption(
      key: 'home',
      icon: LucideIcons.home,
      color: Color(0xFFFBBF24),
    ),
    GoalIconOption(key: 'car', icon: LucideIcons.car, color: Color(0xFFFF6B6B)),
    GoalIconOption(
      key: 'wallet',
      icon: LucideIcons.wallet,
      color: Color(0xFF34D399),
    ),
  ];

  static GoalIconOption resolve(String key) {
    return all.firstWhere((item) => item.key == key, orElse: () => all.first);
  }
}
