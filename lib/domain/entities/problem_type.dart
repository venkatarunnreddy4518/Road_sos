// lib/domain/entities/problem_type.dart
import 'helper.dart';

class ProblemType {
  final String id;
  final String labelKey; // For i18n
  final List<HelperType> mappedTypes;

  ProblemType({
    required this.id,
    required this.labelKey,
    required this.mappedTypes,
  });

  factory ProblemType.fromMap(Map<String, dynamic> map) {
    return ProblemType(
      id: map['id'],
      labelKey: map['label_key'],
      mappedTypes: (map['mapped_types'] as String)
          .split(',')
          .map((t) => HelperType.values.firstWhere((e) => e.toString().split('.').last == t))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label_key': labelKey,
      'mapped_types': mappedTypes.map((e) => e.toString().split('.').last).join(','),
    };
  }
}
