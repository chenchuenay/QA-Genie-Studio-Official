import 'package:equatable/equatable.dart';

class TestStep extends Equatable {
  String action;
  String data;
  String expected;

  TestStep({
    required this.action,
    this.data = '',
    this.expected = '',
  });

  factory TestStep.fromJson(Map<String, dynamic> json) {
    return TestStep(
      action: json['action'] as String? ?? '',
      data: json['data'] as String? ?? '',
      expected: json['expected'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'action': action,
        'data': data,
        'expected': expected,
      };

  TestStep copyWith({
    String? action,
    String? data,
    String? expected,
  }) {
    return TestStep(
      action: action ?? this.action,
      data: data ?? this.data,
      expected: expected ?? this.expected,
    );
  }

  @override
  List<Object?> get props => [action, data, expected];
}