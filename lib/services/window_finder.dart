import '../models/hourly_weather.dart';
import '../models/volleyball_window.dart';

const _perfectWindKmh = 5.0;
const _perfectCloudPct = 40.0;
const _minWindowHours = 2;

bool _isPerfectHour(HourlyWeather h) =>
    h.isDaylight &&
    h.precipitation == 0 &&
    h.windSpeed < _perfectWindKmh &&
    h.cloudCover < _perfectCloudPct;

VolleyballWindow _buildWindow(List<HourlyWeather> block, bool isPerfect) {
  final avgWind =
      block.map((h) => h.windSpeed).reduce((a, b) => a + b) / block.length;
  final maxPrecip =
      block.map((h) => h.precipitation).reduce((a, b) => a > b ? a : b);
  final avgCloud =
      block.map((h) => h.cloudCover).reduce((a, b) => a + b) / block.length;
  final avgTemp =
      block.map((h) => h.temperature).reduce((a, b) => a + b) / block.length;
  return VolleyballWindow(
    start: block.first.time,
    end: block.last.time.add(const Duration(hours: 1)),
    avgWindSpeed: avgWind,
    maxPrecipitation: maxPrecip,
    avgCloudCover: avgCloud,
    avgTemperature: avgTemp,
    isPerfect: isPerfect,
  );
}

void _splitBlock(List<HourlyWeather> block, List<VolleyballWindow> out) {
  final n = block.length;
  final inPerfect = List<bool>.filled(n, false);

  int i = 0;
  while (i < n) {
    if (_isPerfectHour(block[i])) {
      int j = i;
      while (j < n && _isPerfectHour(block[j])) {
        j++;
      }
      if (j - i >= _minWindowHours) {
        for (int k = i; k < j; k++) {
          inPerfect[k] = true;
        }
        out.add(_buildWindow(block.sublist(i, j), true));
      }
      i = j;
    } else {
      i++;
    }
  }

  int segStart = -1;
  for (int k = 0; k <= n; k++) {
    final leftover = k < n && !inPerfect[k];
    if (leftover) {
      if (segStart < 0) segStart = k;
    } else if (segStart >= 0) {
      if (k - segStart >= _minWindowHours) {
        out.add(_buildWindow(block.sublist(segStart, k), false));
      }
      segStart = -1;
    }
  }
}

Map<DateTime, List<VolleyballWindow>> findWindows(List<HourlyWeather> hours) {
  final blocks = <List<HourlyWeather>>[];
  List<HourlyWeather>? current;
  for (final h in hours) {
    if (h.isPlayable && h.isDaylight) {
      (current ??= []).add(h);
    } else if (current != null) {
      blocks.add(current);
      current = null;
    }
  }
  if (current != null) blocks.add(current);

  final flat = <VolleyballWindow>[];
  for (final block in blocks) {
    _splitBlock(block, flat);
  }

  final result = <DateTime, List<VolleyballWindow>>{};
  for (final w in flat) {
    final dayKey = DateTime(w.start.year, w.start.month, w.start.day);
    result.putIfAbsent(dayKey, () => []).add(w);
  }
  for (final list in result.values) {
    list.sort((a, b) {
      if (a.isPerfect != b.isPerfect) return a.isPerfect ? -1 : 1;
      return a.start.compareTo(b.start);
    });
  }
  return result;
}
