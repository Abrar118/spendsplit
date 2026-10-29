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
    DefaultCategorySeed(name: food, icon: 'restaurant', colorValue: 0xFFB5677E),
    DefaultCategorySeed(
      name: transport,
      icon: 'directions_car',
      colorValue: 0xFF7F93B0,
    ),
    DefaultCategorySeed(name: utilities, icon: 'bolt', colorValue: 0xFFC9B48A),
    DefaultCategorySeed(
      name: health,
      icon: 'local_hospital',
      colorValue: 0xFF4DB8AC,
    ),
    DefaultCategorySeed(
      name: shopping,
      icon: 'shopping_bag',
      colorValue: 0xFF9C8CFF,
    ),
    DefaultCategorySeed(
      name: other,
      icon: 'more_horiz',
      colorValue: 0xFF62676F,
    ),
  ];
}

abstract final class DefaultDollarCategories {
  static const games = 'Games';
  static const subscription = 'Subscription';
  static const education = 'Education';

  static const seeds = [
    DefaultCategorySeed(name: games, icon: 'gamepad_2', colorValue: 0xFF7F93B0),
    DefaultCategorySeed(
      name: subscription,
      icon: 'repeat',
      colorValue: 0xFF4DB8AC,
    ),
    DefaultCategorySeed(
      name: education,
      icon: 'graduation_cap',
      colorValue: 0xFF9C8CFF,
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

/// Category colours: a muted data series, kept apart from the saturated
/// legend colours (Available orange, Savings bone, income green, spending
/// red, warning yellow, USD blue) so a category never reads as one of those.
/// Stored as ARGB ints in `categories_table.color`.
abstract final class CategoryColors {
  static const swatches = <int>[
    0xFFB5677E, // rosewood
    0xFF7F93B0, // slate
    0xFFC9B48A, // sand
    0xFF4DB8AC, // teal
    0xFF9C8CFF, // violet
    0xFFA3B35C, // olive
    0xFFB98A6E, // clay
    0xFF62676F, // grey
  ];
}

/// Older builds stored colours that now collide with the legend; draw them
/// as their nearest ramp colour. Stored values are left untouched.
const _legacyCategoryColors = <int, int>{
  0xFFFF6B6B: 0xFFB5677E, // -> rosewood
  0xFF60A5FA: 0xFF7F93B0, // -> slate
  0xFFFBBF24: 0xFFC9B48A, // -> sand
  0xFFF472B6: 0xFFB5677E, // -> rosewood
  0xFF9C7CFF: 0xFF9C8CFF, // -> violet
  0xFF8892A7: 0xFF62676F, // -> grey
  0xFF00E5BF: 0xFF4DB8AC, // -> teal
  0xFFA78BFA: 0xFF9C8CFF, // -> violet
  0xFF34D399: 0xFFA3B35C, // -> olive
  0xFFF26D3D: 0xFFB98A6E, // -> clay
  0xFF34D89C: 0xFFA3B35C, // -> olive
  0xFF9B8BFF: 0xFF9C8CFF, // -> violet
  0xFF7A46E0: 0xFF9C8CFF, // -> violet
  0xFFECB877: 0xFFC9B48A, // -> sand
  0xFFECBB7E: 0xFFC9B48A, // -> sand
  0xFFA6A0B8: 0xFF62676F, // -> grey
  0xFFE86A92: 0xFFB5677E, // -> rosewood
  0xFF5BB8D9: 0xFF7F93B0, // -> slate
  0xFFF2C14E: 0xFFC9B48A, // -> sand
  0xFF8FCB6B: 0xFFA3B35C, // -> olive
  0xFFD98C5F: 0xFFB98A6E, // -> clay
  0xFF4DD0C1: 0xFF4DB8AC, // -> teal
  0xFFA3A8B0: 0xFF62676F, // -> grey
};

/// The colour to draw a category with, given its stored ARGB value.
Color categoryColor(int stored) =>
    Color(_legacyCategoryColors[stored] ?? stored);

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
