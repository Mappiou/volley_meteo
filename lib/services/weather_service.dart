import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hourly_weather.dart';
import '../models/volleyball_window.dart';

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
      '&hourly=precipitation,wind_speed_10m,cloud_cover'
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
      windows: _findWindows(hours),
      hoursByDay: hoursByDay,
    );
  }

  Map<DateTime, List<VolleyballWindow>> _findWindows(List<HourlyWeather> hours) {
    final result = <DateTime, List<VolleyballWindow>>{};
    int? blockStart;

    for (int i = 0; i <= hours.length; i++) {
      final isGood = i < hours.length && hours[i].isPlayable && hours[i].isDaylight;

      if (isGood) {
        blockStart ??= i;
      } else if (blockStart != null) {
        final blockLen = i - blockStart;
        if (blockLen >= 2) {
          final block = hours.sublist(blockStart, i);
          final avgWind = block.map((h) => h.windSpeed).reduce((a, b) => a + b) / block.length;
          final maxPrecip = block.map((h) => h.precipitation).reduce((a, b) => a > b ? a : b);
          final avgCloud = block.map((h) => h.cloudCover).reduce((a, b) => a + b) / block.length;

          final window = VolleyballWindow(
            start: block.first.time,
            end: block.last.time.add(const Duration(hours: 1)),
            avgWindSpeed: avgWind,
            maxPrecipitation: maxPrecip,
            avgCloudCover: avgCloud,
          );

          final dayKey = DateTime(block.first.time.year, block.first.time.month, block.first.time.day);
          result.putIfAbsent(dayKey, () => []).add(window);
        }
        blockStart = null;
      }
    }

    return result;
  }
}
