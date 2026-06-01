import 'package:flutter_test/flutter_test.dart';
import 'package:volley_meteo/models/volleyball_window.dart';

VolleyballWindow win({required double maxWind}) => VolleyballWindow(
      start: DateTime(2026, 6, 1, 10),
      end: DateTime(2026, 6, 1, 12),
      avgWindSpeed: maxWind,
      maxWindSpeed: maxWind,
      maxPrecipitation: 0,
      avgCloudCover: 90,
      avgTemperature: 20,
    );

void main() {
  test('note basée sur le vent max du créneau, jamais sur la moyenne', () {
    expect(win(maxWind: 3).rating, VolleyRating.parfait);
    expect(win(maxWind: 7).rating, VolleyRating.tresBien);
    expect(win(maxWind: 12).rating, VolleyRating.bien);
    expect(win(maxWind: 16).rating, VolleyRating.jouable);
  });
}
