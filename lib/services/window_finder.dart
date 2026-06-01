import '../models/hourly_weather.dart';
import '../models/volleyball_window.dart';

const _minWindowHours = 2;

int _windTier(double wind) {
  if (wind < 5) return 0;
  if (wind < 10) return 1;
  return 2;
}

double _avgWind(List<HourlyWeather> seg) =>
    seg.map((h) => h.windSpeed).reduce((a, b) => a + b) / seg.length;

VolleyballWindow _buildWindow(List<HourlyWeather> seg) {
  final maxWind = seg.map((h) => h.windSpeed).reduce((a, b) => a > b ? a : b);
  final maxPrecip =
      seg.map((h) => h.precipitation).reduce((a, b) => a > b ? a : b);
  final avgCloud =
      seg.map((h) => h.cloudCover).reduce((a, b) => a + b) / seg.length;
  final avgTemp =
      seg.map((h) => h.temperature).reduce((a, b) => a + b) / seg.length;
  return VolleyballWindow(
    start: seg.first.time,
    end: seg.last.time.add(const Duration(hours: 1)),
    avgWindSpeed: _avgWind(seg),
    maxWindSpeed: maxWind,
    maxPrecipitation: maxPrecip,
    avgCloudCover: avgCloud,
    avgTemperature: avgTemp,
  );
}

bool _isBetter(List<HourlyWeather> candidate, List<HourlyWeather> current) {
  if (candidate.length != current.length) {
    return candidate.length > current.length;
  }
  final ca = _avgWind(candidate);
  final cu = _avgWind(current);
  if (ca != cu) return ca < cu;
  return candidate.first.time.isBefore(current.first.time);
}

List<HourlyWeather>? _bestRunAtTier(
    List<List<HourlyWeather>> blocks, int tier) {
  List<HourlyWeather>? best;
  for (final block in blocks) {
    final n = block.length;
    int i = 0;
    while (i < n) {
      if (_windTier(block[i].windSpeed) <= tier) {
        int j = i;
        while (j < n && _windTier(block[j].windSpeed) <= tier) {
          j++;
        }
        if (j - i >= _minWindowHours) {
          final run = block.sublist(i, j);
          if (best == null || _isBetter(run, best)) best = run;
        }
        i = j;
      } else {
        i++;
      }
    }
  }
  return best;
}

Map<DateTime, List<VolleyballWindow>> findWindows(List<HourlyWeather> hours) {
  final blocksByDay = <DateTime, List<List<HourlyWeather>>>{};
  List<HourlyWeather>? current;

  void flush() {
    if (current != null) {
      final d = current!.first.time;
      final key = DateTime(d.year, d.month, d.day);
      blocksByDay.putIfAbsent(key, () => []).add(current!);
      current = null;
    }
  }

  for (final h in hours) {
    if (h.isPlayable && h.isDaylight) {
      (current ??= []).add(h);
    } else {
      flush();
    }
  }
  flush();

  final result = <DateTime, List<VolleyballWindow>>{};
  blocksByDay.forEach((day, blocks) {
    for (int tier = 0; tier <= 2; tier++) {
      final run = _bestRunAtTier(blocks, tier);
      if (run != null) {
        result[day] = [_buildWindow(run)];
        break;
      }
    }
  });
  return result;
}
