import 'package:flutter/material.dart';
import '../models/hourly_weather.dart';

class DayDetailScreen extends StatelessWidget {
  final DateTime day;
  final List<HourlyWeather> hours;

  const DayDetailScreen({super.key, required this.day, required this.hours});

  String _formatDay(DateTime d) {
    const weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  String _skyEmoji(double cloudCover) {
    if (cloudCover < 20) return '☀️';
    if (cloudCover < 40) return '🌤️';
    if (cloudCover < 70) return '⛅';
    return '☁️';
  }

  (Color, Color, String) _hourRating(HourlyWeather h) {
    if (!h.isPlayable) {
      final reason = h.precipitation > 0 ? '🌧️ pluie' : '💨 ${h.windSpeed.toStringAsFixed(0)} km/h';
      return (const Color(0xFF263238), const Color(0xFF546E7A), reason);
    }
    if (h.windSpeed < 5) return (const Color(0xFF00C853), Colors.black87, 'Parfait');
    if (h.windSpeed < 10) return (const Color(0xFF64DD17), Colors.black87, 'Très bien');
    if (h.windSpeed < 15) return (const Color(0xFFFFD600), Colors.black87, 'Bien');
    return (const Color(0xFFFF6D00), Colors.white, 'Jouable');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: Text(_formatDay(day), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hours.length,
        itemBuilder: (context, i) {
          final h = hours[i];
          final (bgColor, textColor, label) = _hourRating(h);
          final hour = '${h.time.hour.toString().padLeft(2, '0')}:00';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2D40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bgColor == const Color(0xFF263238) ? const Color(0xFF37474F) : bgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 44,
                  child: Text(
                    hour,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _skyEmoji(h.cloudCover),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: h.isPlayable ? Colors.white : const Color(0xFF546E7A),
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.air, size: 13, color: textColor),
                      const SizedBox(width: 3),
                      Text(
                        '${h.windSpeed.toStringAsFixed(0)} km/h',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
