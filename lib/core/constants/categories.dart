import 'package:flutter/material.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

class DefaultCategorySeed {
  const DefaultCategorySeed({
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  final String name;
  final String icon;
  final int colorValue;
}

abstract final class DefaultCategories {
  static const food = 'Food';
  static const transport = 'Transport';
  static const utilities = 'Utilities';
  static const health = 'Health';
  static const shopping = 'Shopping';
  static const other = 'Other';

  static const all = [food, transport, utilities, health, shopping, other];

  static const seeds = [
    DefaultCategorySeed(name: food, icon: 'restaurant', colorValue: 0xFFFF6B6B),
    DefaultCategorySeed(
      name: transport,
      icon: 'directions_car',
      colorValue: 0xFF60A5FA,
    ),
    DefaultCategorySeed(name: utilities, icon: 'bolt', colorValue: 0xFFFBBF24),
    DefaultCategorySeed(
      name: health,
      icon: 'local_hospital',
      colorValue: 0xFFF472B6,
    ),
    DefaultCategorySeed(
      name: shopping,
      icon: 'shopping_bag',
      colorValue: 0xFF9C7CFF,
    ),
    DefaultCategorySeed(
      name: other,
      icon: 'more_horiz',
      colorValue: 0xFF8892A7,
    ),
  ];
}

abstract final class DefaultDollarCategories {
  static const games = 'Games';
  static const subscription = 'Subscription';
  static const education = 'Education';

  static const seeds = [
    DefaultCategorySeed(name: games, icon: 'gamepad_2', colorValue: 0xFF60A5FA),
    DefaultCategorySeed(
      name: subscription,
      icon: 'repeat',
      colorValue: 0xFF00E5BF,
    ),
    DefaultCategorySeed(
      name: education,
      icon: 'graduation_cap',
      colorValue: 0xFFA78BFA,
    ),
  ];
}

class CategoryIconOption {
  const CategoryIconOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}

/// The icons offered in the category editor. Keys are stored in
/// `categories_table.icon`. Legacy seed keys still resolve via
/// [iconForCategoryKey].
abstract final class CategoryIcons {
  static const all = [
    CategoryIconOption(key: 'food', icon: LucideIcons.utensils),
    CategoryIconOption(key: 'transport', icon: LucideIcons.car),
    CategoryIconOption(key: 'bills', icon: LucideIcons.zap),
    CategoryIconOption(key: 'health', icon: LucideIcons.heartPulse),
    CategoryIconOption(key: 'shopping', icon: LucideIcons.shoppingBag),
    CategoryIconOption(key: 'entertainment', icon: LucideIcons.gamepad2),
    CategoryIconOption(key: 'travel', icon: LucideIcons.plane),
    CategoryIconOption(key: 'home', icon: LucideIcons.home),
    CategoryIconOption(key: 'education', icon: LucideIcons.graduationCap),
    CategoryIconOption(key: 'work', icon: LucideIcons.briefcase),
    CategoryIconOption(key: 'subscription', icon: LucideIcons.repeat),
    CategoryIconOption(key: 'tech', icon: LucideIcons.cpu),
    CategoryIconOption(key: 'media', icon: LucideIcons.monitor),
    CategoryIconOption(key: 'reading', icon: LucideIcons.bookOpen),
    CategoryIconOption(key: 'savings', icon: LucideIcons.piggyBank),
    CategoryIconOption(key: 'misc', icon: LucideIcons.tag),
  ];
}

/// Accent swatches offered in the category editor. Stored as ARGB ints in
/// `categories_table.color`.
abstract final class CategoryColors {
  static const swatches = <int>[
    0xFFF26D3D, // coral
    0xFF34D89C, // green
    0xFF9B8BFF, // purple
    0xFF7A46E0, // deep violet
    0xFFECB877, // amber
    0xFFECBB7E, // gold
    0xFFF472B6, // pink
    0xFFA6A0B8, // neutral
  ];
}

IconData iconForCategoryKey(String iconName) {
  for (final option in CategoryIcons.all) {
    if (option.key == iconName) return option.icon;
  }
  switch (iconName) {
    case 'restaurant':
      return LucideIcons.utensils;
    case 'directions_car':
      return LucideIcons.car;
    case 'bolt':
      return LucideIcons.zap;
    case 'local_hospital':
      return LucideIcons.heartPulse;
    case 'shopping_bag':
      return LucideIcons.shoppingBag;
    case 'more_horiz':
      return LucideIcons.moreHorizontal;
    case 'school':
      return LucideIcons.graduationCap;
    case 'monitor':
      return LucideIcons.monitor;
    case 'book':
      return LucideIcons.bookOpen;
    case 'cpu':
      return LucideIcons.cpu;
    case 'globe':
      return LucideIcons.globe2;
    case 'briefcase':
      return LucideIcons.briefcase;
    case 'gamepad_2':
      return LucideIcons.gamepad2;
    case 'repeat':
      return LucideIcons.repeat;
    case 'graduation_cap':
      return LucideIcons.graduationCap;
    default:
      return LucideIcons.tag;
  }
}
