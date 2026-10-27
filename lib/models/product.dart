class Product {
  final String id;
  String name;
  String description;
  String strength;
  String type; // 'Indica', 'Sativa', 'Hybrid', 'Extract'
  DateTime datePurchased;
  DateTime? dateOpened;
  DateTime? dateFinished;
  double rating; // 1.0 to 10.0
  String reviewNotes;
  String source;
  double remainingGrams;
  double totalGrams;
  double price;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.strength,
    required this.type,
    required this.datePurchased,
    this.dateOpened,
    this.dateFinished,
    required this.rating,
    required this.reviewNotes,
    required this.source,
    required this.remainingGrams,
    required this.totalGrams,
    required this.price,
    this.isFavorite = false,
  });

  bool get isOpen => dateOpened != null && dateFinished == null;
  bool get isFinished => dateFinished != null;
  bool get isUnopened => dateOpened == null;

  double get progress => totalGrams > 0 ? (remainingGrams / totalGrams).clamp(0.0, 1.0) : 0.0;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? strength,
    String? type,
    DateTime? datePurchased,
    DateTime? dateOpened,
    DateTime? dateFinished,
    double? rating,
    String? reviewNotes,
    String? source,
    double? remainingGrams,
    double? totalGrams,
    double? price,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      strength: strength ?? this.strength,
      type: type ?? this.type,
      datePurchased: datePurchased ?? this.datePurchased,
      dateOpened: dateOpened ?? this.dateOpened,
      dateFinished: dateFinished ?? this.dateFinished,
      rating: rating ?? this.rating,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      source: source ?? this.source,
      remainingGrams: remainingGrams ?? this.remainingGrams,
      totalGrams: totalGrams ?? this.totalGrams,
      price: price ?? this.price,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'strength': strength,
      'type': type,
      'datePurchased': datePurchased.toIso8601String(),
      'dateOpened': dateOpened?.toIso8601String(),
      'dateFinished': dateFinished?.toIso8601String(),
      'rating': rating,
      'reviewNotes': reviewNotes,
      'source': source,
      'remainingGrams': remainingGrams,
      'totalGrams': totalGrams,
      'price': price,
      'isFavorite': isFavorite,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? 'prod-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unnamed Cultivar',
      description: json['description'] as String? ?? '',
      strength: json['strength'] as String? ?? '22.0% THC',
      type: json['type'] as String? ?? 'Hybrid',
      datePurchased: DateTime.tryParse(json['datePurchased']?.toString() ?? '') ?? DateTime.now(),
      dateOpened: json['dateOpened'] != null ? DateTime.tryParse(json['dateOpened'].toString()) : null,
      dateFinished: json['dateFinished'] != null ? DateTime.tryParse(json['dateFinished'].toString()) : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 9.0,
      reviewNotes: json['reviewNotes'] as String? ?? '',
      source: json['source'] as String? ?? '',
      remainingGrams: (json['remainingGrams'] as num?)?.toDouble() ?? 14.0,
      totalGrams: (json['totalGrams'] as num?)?.toDouble() ?? 14.0,
      price: (json['price'] as num?)?.toDouble() ?? 120.0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
