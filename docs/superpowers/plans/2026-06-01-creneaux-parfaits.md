# Créneaux parfaits prioritaires — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire remonter en tête de chaque jour, sur la page d'accueil, les créneaux strictement parfaits (≥ 2h), sans rien cacher des autres créneaux, et sans toucher au détail du jour.

**Architecture:** La détection des créneaux passe d'une logique « bloc moyenné » à une logique de découpage : on extrait d'abord les segments où **chaque heure** est parfaite (vent < 5 km/h, ciel dégagé, jour, sans pluie) d'au moins 2h, puis les heures jouables restantes forment des créneaux non-parfaits. Le tri perfect-first est calculé dans la couche logique (`window_finder.dart`), donc l'UI reste passive.

**Tech Stack:** Flutter / Dart, `flutter_test`.

---

## Structure des fichiers

- Créer : `lib/services/window_finder.dart` — fonction pure `findWindows(hours)` (détection + découpage + tri).
- Créer : `test/window_finder_test.dart` — tests unitaires de la fonction pure.
- Modifier : `lib/models/volleyball_window.dart` — champ `isPerfect` + note basée dessus.
- Créer : `test/volleyball_window_test.dart` — tests de la note.
- Modifier : `lib/services/weather_service.dart` — délègue à `findWindows`, supprime `_findWindows`.
- Inchangé : `lib/screens/home_screen.dart` (rend déjà les créneaux dans l'ordre reçu), `lib/screens/day_detail_screen.dart`.

---

### Task 1 : note du créneau basée sur `isPerfect`

**Files:**
- Modify: `lib/models/volleyball_window.dart`
- Test: `test/volleyball_window_test.dart`

- [ ] **Step 1 : Écrire le test qui échoue**

```dart
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
```

- [ ] **Step 2 : Lancer le test, vérifier l'échec**

Run: `flutter test test/volleyball_window_test.dart`
Expected: FAIL (le constructeur ne connaît pas `isPerfect`).

- [ ] **Step 3 : Implémenter**

Remplacer la fin de `lib/models/volleyball_window.dart` (champs + constructeur + `_isSunny` + `rating`) par :

```dart
class VolleyballWindow {
  final DateTime start;
  final DateTime end;
  final double avgWindSpeed;
  final double maxPrecipitation;
  final double avgCloudCover;
  final double avgTemperature;
  final bool isPerfect;

  const VolleyballWindow({
    required this.start,
    required this.end,
    required this.avgWindSpeed,
    required this.maxPrecipitation,
    required this.avgCloudCover,
    required this.avgTemperature,
    this.isPerfect = false,
  });

  Duration get duration => end.difference(start);

  VolleyRating get rating {
    if (isPerfect) return VolleyRating.parfait;
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
```

- [ ] **Step 4 : Lancer le test, vérifier le succès**

Run: `flutter test test/volleyball_window_test.dart`
Expected: PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/models/volleyball_window.dart test/volleyball_window_test.dart
git commit -m "feat(window): note basée sur isPerfect"
```

---

### Task 2 : détection + découpage + tri dans `window_finder.dart`

**Files:**
- Create: `lib/services/window_finder.dart`
- Test: `test/window_finder_test.dart`

- [ ] **Step 1 : Écrire les tests qui échouent**

```dart
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
```

- [ ] **Step 2 : Lancer les tests, vérifier l'échec**

Run: `flutter test test/window_finder_test.dart`
Expected: FAIL (`findWindows` introuvable).

- [ ] **Step 3 : Implémenter `window_finder.dart`**

```dart
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
```

- [ ] **Step 4 : Lancer les tests, vérifier le succès**

Run: `flutter test test/window_finder_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5 : Commit**

```bash
git add lib/services/window_finder.dart test/window_finder_test.dart
git commit -m "feat(window): détection créneaux parfaits stricts + tri perfect-first"
```

---

### Task 3 : brancher `WeatherService` sur `findWindows`

**Files:**
- Modify: `lib/services/weather_service.dart`

- [ ] **Step 1 : Ajouter l'import**

En haut de `lib/services/weather_service.dart`, après les imports existants :

```dart
import 'window_finder.dart';
```

- [ ] **Step 2 : Utiliser `findWindows`**

Dans `fetchWindows`, remplacer `windows: _findWindows(hours),` par :

```dart
      windows: findWindows(hours),
```

- [ ] **Step 3 : Supprimer l'ancienne méthode**

Supprimer entièrement la méthode privée `_findWindows` (de `Map<DateTime, List<VolleyballWindow>> _findWindows(...)` jusqu'à son `}` final).

- [ ] **Step 4 : Vérifier que tout compile et que la suite passe**

Run: `flutter analyze && flutter test`
Expected: 0 erreur d'analyse, tous les tests PASS (y compris `test/widget_test.dart`).

- [ ] **Step 5 : Commit**

```bash
git add lib/services/weather_service.dart
git commit -m "refactor(service): délègue la détection à findWindows"
```

---

## Self-review

- **Couverture spec** : créneau parfait strict ≥ 2h (Task 2 test 1) ; priorité perfect-first tous jours (Task 2 test 4, tri intégré) ; pas de doublon horaire (Task 2 test 3, `windows[0].end == windows[1].start`) ; note Parfait réservée aux créneaux stricts (Task 1) ; détail du jour inchangé (aucune tâche ne touche `day_detail_screen.dart`).
- **Placeholders** : aucun ; tout le code est fourni.
- **Cohérence des types** : `findWindows`, `VolleyballWindow.isPerfect`, `_splitBlock`, `_buildWindow` cohérents entre tâches.
- **UI** : `home_screen.dart` rend `windows` dans l'ordre reçu ; le tri étant fait dans `findWindows`, aucune modification UI nécessaire.
