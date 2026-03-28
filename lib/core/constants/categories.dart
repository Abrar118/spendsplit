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
