import 'package:fvm/src/services/releases_service/models/release.model.dart';

enum Channel { stable, dev, beta }

class Channels {
  Channels({
    this.beta,
    this.dev,
    this.stable,
  });

  final Release beta;
  final Release dev;
  final Release stable;

  factory Channels.fromMap(Map<String, dynamic> json) => Channels(
        beta: Release.fromMap(json['beta'] as Map<String, dynamic>),
        dev: Release.fromMap(json['dev'] as Map<String, dynamic>),
        stable: Release.fromMap(json['stable'] as Map<String, dynamic>),
      );

  Release operator [](String key) {
    if (key == 'beta') return beta;
    if (key == 'dev') return dev;
    if (key == 'stable') return stable;
    return null;
  }

  Map<String, dynamic> toMap() => {
        'beta': beta,
        'dev': dev,
        'stable': stable,
      };

  Map<String, dynamic> toHashMap() => {
        '${beta.hash}': 'beta',
        '${dev.hash}': 'dev',
        '${stable.hash}': 'stable',
      };
}

final channelValues = EnumValues(
    {'beta': Channel.beta, 'dev': Channel.dev, 'stable': Channel.stable});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap ??= map.map((k, v) => MapEntry(v, k));

    return reverseMap;
  }
}
