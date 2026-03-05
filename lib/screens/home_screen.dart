import 'package:flutter/material.dart';
import '../models/hourly_weather.dart';
import '../models/volleyball_window.dart';
import '../services/weather_service.dart';
import 'day_detail_screen.dart';

enum _AppState { idle, loading, loaded, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _service = WeatherService();
  _AppState _state = _AppState.idle;
  ForecastData? _forecast;
  String _errorMessage = '';
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = _AppState.loading);
    try {
      final forecast = await _service.fetchWindows();
      setState(() {
        _forecast = forecast;
        _state = _AppState.loaded;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = _AppState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: _state == _AppState.loaded || _state == _AppState.error
          ? AppBar(
              backgroundColor: const Color(0xFF0D1B2A),
              title: const Text('Volley Météo', style: TextStyle(color: Colors.white)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _load,
                ),
              ],
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_state) {
          _AppState.idle => _buildIdle(),
          _AppState.loading => _buildLoading(),
          _AppState.loaded => _buildResults(),
          _AppState.error => _buildError(),
        },
      ),
    );
  }

  Widget _buildIdle() {
    return Center(
      key: const ValueKey('idle'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_volleyball, size: 80, color: Color(0xFF4FC3F7)),
          const SizedBox(height: 24),
          const Text(
            'Volley Météo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Barcelone · 7 jours',
            style: TextStyle(color: Color(0xFF90A4AE), fontSize: 16),
          ),
          const SizedBox(height: 56),
          ScaleTransition(
            scale: _pulseAnim,
            child: ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: const Color(0xFF0D1B2A),
                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              child: const Text('START'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      key: ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4FC3F7)),
          SizedBox(height: 24),
          Text(
            'Chargement des conditions...',
            style: TextStyle(color: Color(0xFF90A4AE), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final forecast = _forecast!;
    final days = List<DateTime>.generate(7, (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + i);
    });

    return ListView.builder(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return _DayCard(
          day: day,
          windows: forecast.windows[day] ?? [],
          hoursByDay: forecast.hoursByDay[day] ?? [],
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Color(0xFF90A4AE)),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger la météo',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: const Color(0xFF0D1B2A),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final List<VolleyballWindow> windows;
  final List<HourlyWeather> hoursByDay;

  const _DayCard({required this.day, required this.windows, required this.hoursByDay});

  String _formatDay(DateTime d) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return 'Aujourd\'hui · ${d.day} ${months[d.month - 1]}';
    if (d == today.add(const Duration(days: 1))) return 'Demain · ${d.day} ${months[d.month - 1]}';
    return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  String _formatHour(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final h = d.inHours;
    return h == 1 ? '1h' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hoursByDay.isNotEmpty
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DayDetailScreen(day: day, hours: hoursByDay),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2D40),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDay(day),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hoursByDay.isNotEmpty)
                    const Icon(Icons.chevron_right, color: Color(0xFF546E7A), size: 20),
                ],
              ),
            ),
            if (windows.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'Pas de créneau favorable',
                  style: TextStyle(color: Color(0xFF546E7A), fontSize: 14),
                ),
              )
            else
              ...windows.map((w) => _WindowRow(window: w, formatHour: _formatHour, formatDuration: _formatDuration)),
            if (windows.isNotEmpty) const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _WindowRow extends StatelessWidget {
  final VolleyballWindow window;
  final String Function(DateTime) formatHour;
  final String Function(Duration) formatDuration;

  const _WindowRow({
    required this.window,
    required this.formatHour,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final rating = window.rating;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rating.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rating.label,
              style: TextStyle(
                color: rating.textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            window.skyEmoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Text(
            '${formatHour(window.start)} – ${formatHour(window.end)}',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            formatDuration(window.duration),
            style: const TextStyle(color: Color(0xFF78909C), fontSize: 13),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.air, size: 14, color: Color(0xFF78909C)),
              const SizedBox(width: 3),
              Text(
                '${window.avgWindSpeed.toStringAsFixed(0)} km/h',
                style: const TextStyle(color: Color(0xFF78909C), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
