import 'package:flutter_test/flutter_test.dart';
import 'package:volley_meteo/models/volleyball_window.dart';

VolleyballWindow win({required double wind, required bool isPerfect}) => VolleyballWindow(
      start: DateTime(2026, 6, 1, 10),
      end: DateTime(2026, 6, 1, 12),
      avgWindSpeed: wind,
      maxPrecipitation: 0,
      avgCloudCover: 90,
      avgTemperature: 20,
      isPerfect: isPerfect,
    );

void main() {
  test('isPerfect force la note Parfait quel que soit le vent', () {
    expect(win(wind: 12, isPerfect: true).rating, VolleyRating.parfait);
  });

  test('sans isPerfect, la note suit le vent et n\'est jamais Parfait', () {
    expect(win(wind: 3, isPerfect: false).rating, VolleyRating.tresBien);
    expect(win(wind: 7, isPerfect: false).rating, VolleyRating.bien);
    expect(win(wind: 12, isPerfect: false).rating, VolleyRating.jouable);
  });
}
