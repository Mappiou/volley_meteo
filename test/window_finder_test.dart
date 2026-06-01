import 'package:flutter_test/flutter_test.dart';
import 'package:volley_meteo/models/hourly_weather.dart';
import 'package:volley_meteo/models/volleyball_window.dart';
import 'package:volley_meteo/services/window_finder.dart';

HourlyWeather hw(int hour,
        {required double wind,
        double precip = 0,
        double cloud = 10,
        double temp = 20,
        bool daylight = true}) =>
    HourlyWeather(
      time: DateTime(2026, 6, 1, hour),
      windSpeed: wind,
      precipitation: precip,
      cloudCover: cloud,
      temperature: temp,
      isDaylight: daylight,
    );

DateTime get day => DateTime(2026, 6, 1);

void main() {
  test('un seul créneau par jour : le matin calme, pas tout le bloc', () {
    final res = findWindows([
      hw(7, wind: 3), hw(8, wind: 3), hw(9, wind: 4),
      hw(10, wind: 8), hw(11, wind: 9),
      hw(12, wind: 12), hw(13, wind: 13), hw(14, wind: 13),
    ]);
    final windows = res[day]!;
    expect(windows.length, 1);
    expect(windows.first.rating, VolleyRating.parfait);
    expect(windows.first.start.hour, 7);
    expect(windows.first.end.hour, 10);
  });

  test('pas de calme < 5 : on prend le meilleur tier disponible', () {
    final res = findWindows([hw(8, wind: 8), hw(9, wind: 8), hw(10, wind: 8)]);
    final windows = res[day]!;
    expect(windows.length, 1);
    expect(windows.first.rating, VolleyRating.tresBien);
    expect(windows.first.start.hour, 8);
    expect(windows.first.end.hour, 11);
  });

  test('un calme de 2h est préféré à un long créneau plus venteux', () {
    final res = findWindows([
      hw(7, wind: 3), hw(8, wind: 3),
      hw(9, wind: 8), hw(10, wind: 8), hw(11, wind: 8), hw(12, wind: 8),
    ]);
    final windows = res[day]!;
    expect(windows.length, 1);
    expect(windows.first.rating, VolleyRating.parfait);
    expect(windows.first.start.hour, 7);
    expect(windows.first.end.hour, 9);
  });

  test('durée variable : le calme s\'étend tant que le vent reste bas', () {
    final res = findWindows([
      hw(7, wind: 3), hw(8, wind: 3), hw(9, wind: 3),
      hw(10, wind: 4), hw(11, wind: 4),
    ]);
    final windows = res[day]!;
    expect(windows.length, 1);
    expect(windows.first.start.hour, 7);
    expect(windows.first.end.hour, 12);
  });

  test('un bloc de moins de 2h ne donne aucun créneau', () {
    final res = findWindows([hw(7, wind: 3)]);
    expect(res.isEmpty, true);
  });

  test('la pluie et la nuit cassent les blocs', () {
    final res = findWindows([
      hw(7, wind: 3, precip: 1),
      hw(8, wind: 3, daylight: false),
      hw(9, wind: 3), hw(10, wind: 3),
    ]);
    final windows = res[day]!;
    expect(windows.length, 1);
    expect(windows.first.start.hour, 9);
    expect(windows.first.end.hour, 11);
  });
}
