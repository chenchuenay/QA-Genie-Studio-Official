enum PropertyType {
  string,
  email,
  url,
  phone,
  number,
  integer,
  boolean,
  date,
  password,
  token,
  code,
  enum_,
  text,
  percent,
  hexColor,
  ipAddress,
  port,
  coordinates,
}

class PropertyDef {
  final String name;
  final String displayName;
  final String? label;
  final PropertyType type;
  final bool required;
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? pattern;
  final String? example;
  final String? invalidExample;
  final String? boundaryLow;
  final String? boundaryHigh;
  final List<String>? enumValues;
  final bool isSensitive;
  final bool isIdentifier;
  final String? hint;

  const PropertyDef({
    required this.name,
    required this.displayName,
    this.label,
    this.type = PropertyType.string,
    this.required = false,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.pattern,
    this.example,
    this.invalidExample,
    this.boundaryLow,
    this.boundaryHigh,
    this.enumValues,
    this.isSensitive = false,
    this.isIdentifier = false,
    this.hint,
  });

  String get effectiveLabel => label ?? displayName;

  String getPlatformLabel(String platform) {
    if (platform == 'API') return name;
    return effectiveLabel;
  }
}

class EntityDef {
  final String id;
  final String displayName;
  final String? pluralDisplayName;
  final List<PropertyDef> properties;
  final List<String> synonyms;

  const EntityDef({
    required this.id,
    required this.displayName,
    this.pluralDisplayName,
    this.properties = const [],
    this.synonyms = const [],
  });

  PropertyDef? property(String name) {
    for (final p in properties) {
      if (p.name == name) return p;
    }
    return null;
  }

  List<PropertyDef> get requiredProperties =>
      properties.where((p) => p.required).toList();

  List<PropertyDef> get identifierProperties =>
      properties.where((p) => p.isIdentifier).toList();

  String get plural => pluralDisplayName ?? '${displayName}s';
}
