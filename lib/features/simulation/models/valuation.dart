class ValuationCategory {
  const ValuationCategory(this.id, this.name, this.iconAsset);
  final String id;
  final String name;
  final String iconAsset;
}

class ValuationBrand {
  const ValuationBrand(
    this.name, {
    this.popular = false,
    this.logoAsset,
    this.logoWidth = 70,
    this.logoHeight = 24,
    this.cropLogo = false,
  });
  final String name;
  final bool popular;
  final String? logoAsset;
  final double logoWidth;
  final double logoHeight;
  final bool cropLogo;
}

class ValuationModel {
  const ValuationModel(
    this.name,
    this.variant, {
    this.imageAsset,
    this.listLabel,
  });
  final String name;
  final String variant;
  final String? imageAsset;

  /// Text in the model list when the name alone is not enough (same model, several variants).
  final String? listLabel;
  String get label => listLabel ?? name;
}

class ValuationResult {
  const ValuationResult({
    required this.category,
    required this.brand,
    required this.model,
    required this.minimum,
    required this.maximum,
  });
  final ValuationCategory category;
  final ValuationBrand brand;
  final ValuationModel model;
  final int minimum;
  final int maximum;
  String get productName => '${brand.name} ${model.name}';
}
