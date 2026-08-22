import 'package:flutter/foundation.dart';

import 'link_parameter.dart';
import 'user_type.dart';

@immutable
class GeneratedLink {
  const GeneratedLink({
    required this.url,
    required this.entryId,
    required this.destinationPage,
    required this.rank,
    required this.pathPattern,
    required this.parameters,
    this.testedUserType,
  });

  final String url;
  final String entryId;
  final String destinationPage;
  final int rank;
  final String pathPattern;
  final List<LinkParameter> parameters;
  final UserType? testedUserType;

  static const String adHocId = '';
  static const String adHocPage = 'Ad-hoc link';

  factory GeneratedLink.adHoc(String url) => GeneratedLink(
        url: url.trim(),
        entryId: adHocId,
        destinationPage: adHocPage,
        rank: 0,
        pathPattern: url.trim(),
        parameters: const <LinkParameter>[],
      );

  bool get isAdHoc => entryId.isEmpty;

  Map<String, String> get appliedParameters => <String, String>{
        for (final LinkParameter p in parameters)
          if (p.isIncluded) p.name: p.trimmedValue,
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'entryId': entryId,
        'destinationPage': destinationPage,
        'rank': rank,
        'pathPattern': pathPattern,
        'parameters': parameters.map((LinkParameter p) => p.toJson()).toList(),
        'testedUserType': testedUserType?.code,
      };

  factory GeneratedLink.fromJson(Map<String, dynamic> json) => GeneratedLink(
        url: json['url'] as String? ?? '',
        entryId: json['entryId'] as String? ?? '',
        destinationPage: json['destinationPage'] as String? ?? 'Unknown',
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        pathPattern: json['pathPattern'] as String? ?? '',
        parameters: (json['parameters'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                LinkParameter.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        testedUserType:
            UserType.fromCode(json['testedUserType'] as String? ?? ''),
      );
}
