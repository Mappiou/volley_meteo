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
  test('3 heures toutes parfaites -> un créneau parfait de 3h', () {
    final res = findWindows([hw(10, wind: 2), hw(11, wind: 3), hw(12, wind: 4)]);
    final windows = res[day]!;
    expect(windows.length, 1);
    expect(windows.first.isPerfect, true);
    expect(windows.first.rating, VolleyRating.parfait);
    expect(windows.first.start.hour, 10);
    expect(windows.first.end.hour, 13);
  });

  test('une heure parfaite isolée dans un bloc reste non-parfaite', () {
    final res = findWindows([hw(10, wind: 2), hw(11, wind: 8), hw(12, wind: 8)]);
    final windows = res[day]!;
    expect(windows.length, 1);
    expect(windows.first.isPerfect, false);
  });

  test('parfait puis venteux -> deux créneaux adjacents sans chevauchement', () {
    final res = findWindows([
      hw(10, wind: 2), hw(11, wind: 2), hw(12, wind: 2),
      hw(13, wind: 8), hw(14, wind: 8), hw(15, wind: 8),
    ]);
    final windows = res[day]!;
    expect(windows.length, 2);
    expect(windows[0].isPerfect, true);
    expect(windows[1].isPerfect, false);
    expect(windows[0].end, windows[1].start);
  });

  test('un créneau parfait plus tard est trié avant un non-parfait plus tôt', () {
    final res = findWindows([
      hw(8, wind: 8), hw(9, wind: 8),
      hw(10, wind: 50),
      hw(11, wind: 2), hw(12, wind: 2), hw(13, wind: 2),
    ]);
    final windows = res[day]!;
    expect(windows.length, 2);
    expect(windows[0].isPerfect, true);
    expect(windows[0].start.hour, 11);
    expect(windows[1].isPerfect, false);
    expect(windows[1].start.hour, 8);
  });

  test('bloc de moins de 2h ignoré', () {
    final res = findWindows([hw(10, wind: 2)]);
    expect(res.isEmpty, true);
  });
}
