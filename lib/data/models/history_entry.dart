import 'package:flutter/foundation.dart';

import 'generated_link.dart';

enum LinkAction {
  generated('Generated'),
  launched('Launched'),
  shared('Shared'),
  qrSaved('QR saved');

  const LinkAction(this.label);
  final String label;

  static LinkAction fromName(String? name) => LinkAction.values.firstWhere(
        (LinkAction e) => e.name == name,
        orElse: () => LinkAction.generated,
      );
}

@immutable
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.link,
    required this.action,
    required this.timestamp,
  });

  final String id;
  final GeneratedLink link;
  final LinkAction action;
  final DateTime timestamp;

  String get url => link.url;
  String get title => link.destinationPage;

  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final String index =
        '$title ${link.url} ${link.appliedParameters}'.toLowerCase();
    return q.split(RegExp(r'\s+')).every(index.contains);
  }

  HistoryEntry copyWith({
    String? id,
    GeneratedLink? link,
    LinkAction? action,
    DateTime? timestamp,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      link: link ?? this.link,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'link': link.toJson(),
        'action': action.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        link: GeneratedLink.fromJson(
            Map<String, dynamic>.from(json['link'] as Map)),
        action: LinkAction.fromName(json['action'] as String?),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HistoryEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
