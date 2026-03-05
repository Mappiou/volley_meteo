import 'package:flutter/material.dart';

enum VolleyRating { parfait, tresBien, bien, jouable }

extension VolleyRatingExt on VolleyRating {
  String get label {
    switch (this) {
      case VolleyRating.parfait:
        return 'Parfait';
      case VolleyRating.tresBien:
        return 'Très bien';
      case VolleyRating.bien:
        return 'Bien';
      case VolleyRating.jouable:
        return 'Jouable';
    }
  }

  Color get color {
    switch (this) {
      case VolleyRating.parfait:
        return const Color(0xFF00C853);
      case VolleyRating.tresBien:
        return const Color(0xFF64DD17);
      case VolleyRating.bien:
        return const Color(0xFFFFD600);
      case VolleyRating.jouable:
        return const Color(0xFFFF6D00);
    }
  }

  Color get textColor {
    switch (this) {
      case VolleyRating.parfait:
      case VolleyRating.tresBien:
        return Colors.black87;
      case VolleyRating.bien:
        return Colors.black87;
      case VolleyRating.jouable:
        return Colors.white;
    }
  }
}

class VolleyballWindow {
  final DateTime start;
  final DateTime end;
  final double avgWindSpeed;
  final double maxPrecipitation;
  final double avgCloudCover;

  const VolleyballWindow({
    required this.start,
    required this.end,
    required this.avgWindSpeed,
    required this.maxPrecipitation,
    required this.avgCloudCover,
  });

  Duration get duration => end.difference(start);

  bool get _isSunny => avgCloudCover < 40;

  VolleyRating get rating {
    if (avgWindSpeed < 5 && _isSunny) return VolleyRating.parfait;
    if (avgWindSpeed < 5) return VolleyRating.tresBien;
    if (avgWindSpeed < 10) return VolleyRating.bien;
    return VolleyRating.jouable;
  }

  String get skyEmoji {
    if (avgCloudCover < 20) return '☀️';
    if (avgCloudCover < 40) return '🌤️';
    if (avgCloudCover < 70) return '⛅';
    return '☁️';
  }
}
