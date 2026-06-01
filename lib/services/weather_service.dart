import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hourly_weather.dart';
import '../models/volleyball_window.dart';
import 'window_finder.dart';

class ForecastData {
  final Map<DateTime, List<VolleyballWindow>> windows;
  final Map<DateTime, List<HourlyWeather>> hoursByDay;

  const ForecastData({required this.windows, required this.hoursByDay});
}

class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _lat = 41.3828;
  static const _lon = 2.1769;

  Future<ForecastData> fetchWindows() async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=$_lat&longitude=$_lon'
      '&hourly=precipitation,wind_speed_10m,cloud_cover,temperature_2m'
      '&daily=sunrise,sunset'
      '&timezone=Europe%2FMadrid'
      '&forecast_days=7'
      '&wind_speed_unit=kmh',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Erreur API: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final daily = data['daily'] as Map<String, dynamic>;
    final sunrises = (daily['sunrise'] as List<dynamic>).map((s) => DateTime.parse(s as String)).toList();
    final sunsets = (daily['sunset'] as List<dynamic>).map((s) => DateTime.parse(s as String)).toList();

    final daylightByDay = <DateTime, (DateTime, DateTime)>{};
    for (int i = 0; i < sunrises.length; i++) {
      final day = DateTime(sunrises[i].year, sunrises[i].month, sunrises[i].day);
      daylightByDay[day] = (sunrises[i], sunsets[i]);
    }

    final hourly = data['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List<dynamic>;
    final winds = hourly['wind_speed_10m'] as List<dynamic>;
    final precips = hourly['precipitation'] as List<dynamic>;
    final clouds = hourly['cloud_cover'] as List<dynamic>;
    final temps = hourly['temperature_2m'] as List<dynamic>;

    final hours = List.generate(times.length, (i) {
      final t = DateTime.parse(times[i] as String);
      final day = DateTime(t.year, t.month, t.day);
      final daylight = daylightByDay[day];
      final isDaylight = daylight != null && !t.isBefore(daylight.$1) && t.isBefore(daylight.$2);
      return HourlyWeather(
        time: t,
        windSpeed: (winds[i] as num).toDouble(),
        precipitation: (precips[i] as num).toDouble(),
        cloudCover: (clouds[i] as num).toDouble(),
        temperature: (temps[i] as num).toDouble(),
        isDaylight: isDaylight,
      );
    });

    final hoursByDay = <DateTime, List<HourlyWeather>>{};
    for (final h in hours) {
      if (h.isDaylight) {
        final day = DateTime(h.time.year, h.time.month, h.time.day);
        hoursByDay.putIfAbsent(day, () => []).add(h);
      }
    }

    return ForecastData(
      windows: findWindows(hours),
      hoursByDay: hoursByDay,
    );
  }
}
