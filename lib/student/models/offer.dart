class Offer {
  final String id;
  final String title;
  final String code;
  final String description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<String> applicableCourses;
  final int? usageLimit;
  final int usageCount;
  final double minPurchaseAmount;
  final DateTime createdAt;

  Offer({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.applicableCourses,
    this.usageLimit,
    required this.usageCount,
    required this.minPurchaseAmount,
    required this.createdAt,
  });

  // Create Offer from Map (API response)
  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['_id'] ?? map['id'] ?? '',
      title: map['title'] ?? '',
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      discountType: map['discountType'] ?? 'percentage',
      discountValue: (map['discountValue'] ?? 0).toDouble(),
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate:
          DateTime.tryParse(map['endDate'] ?? '') ??
          DateTime.now().add(Duration(days: 30)),
      isActive: map['isActive'] ?? false,
      applicableCourses: List<String>.from(map['applicableCourses'] ?? []),
      usageLimit: map['usageLimit'],
      usageCount: map['usageCount'] ?? 0,
      minPurchaseAmount: (map['minPurchaseAmount'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Convert Offer to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'applicableCourses': applicableCourses,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'minPurchaseAmount': minPurchaseAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (usageLimit == null || usageCount < usageLimit!);
  }

  String get discountText {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}%';
    } else {
      return '\$${discountValue.toStringAsFixed(2)}';
    }
  }

  String get validityText {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.inDays > 0) {
      return 'Valid for ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'Valid for ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'Valid for ${difference.inMinutes} minutes';
    } else if (difference.inSeconds > 0) {
      return 'Expires soon';
    } else {
      return 'Expired';
    }
  }

  String get formattedEndDate {
    return '${endDate.day}/${endDate.month}/${endDate.year}';
  }

  String get formattedStartDate {
    return '${startDate.day}/${startDate.month}/${startDate.year}';
  }

  String get dateRangeText {
    return '$formattedStartDate - $formattedEndDate';
  }

  String get detailedValidityText {
    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      final difference = startDate.difference(now);
      if (difference.inDays > 0) {
        return 'Starts in ${difference.inDays} days ($formattedStartDate)';
      } else {
        return 'Starts soon ($formattedStartDate)';
      }
    } else if (now.isAfter(endDate)) {
      final difference = now.difference(endDate);
      if (difference.inDays > 0) {
        return 'Expired ${difference.inDays} days ago ($formattedEndDate)';
      } else if (difference.inHours > 0) {
        return 'Expired ${difference.inHours} hours ago ($formattedEndDate)';
      } else {
        return 'Expired recently ($formattedEndDate)';
      }
    } else {
      final difference = endDate.difference(now);
      if (difference.inDays > 0) {
        return 'Expires in ${difference.inDays} days ($formattedEndDate)';
      } else if (difference.inHours > 0) {
        return 'Expires in ${difference.inHours} hours ($formattedEndDate)';
      } else {
        return 'Expires soon ($formattedEndDate)';
      }
    }
  }

  // Calculate discount amount for a given price
  double calculateDiscount(double price) {
    if (discountType == 'percentage') {
      return price * (discountValue / 100);
    } else {
      return discountValue;
    }
  }

  // Calculate final price after discount
  double calculateFinalPrice(double price) {
    final discount = calculateDiscount(price);
    return (price - discount).clamp(0.0, double.infinity);
  }

  @override
  String toString() {
    return 'Offer(id: $id, title: $title, code: $code, discountType: $discountType, discountValue: $discountValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Offer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
