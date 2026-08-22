import 'package:flutter/foundation.dart';

@immutable
class EntryUsage {
  const EntryUsage({
    required this.entryId,
    required this.count,
    required this.lastUsedAt,
  });

  final String entryId;
  final int count;
  final DateTime lastUsedAt;

  EntryUsage increment() => EntryUsage(
        entryId: entryId,
        count: count + 1,
        lastUsedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'entryId': entryId,
        'count': count,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  factory EntryUsage.fromJson(Map<String, dynamic> json) => EntryUsage(
        entryId: json['entryId'] as String,
        count: (json['count'] as num?)?.toInt() ?? 0,
        lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
