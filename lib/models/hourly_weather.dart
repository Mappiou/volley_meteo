class HourlyWeather {
  final DateTime time;
  final double windSpeed;
  final double precipitation;
  final bool isDaylight;
  final double cloudCover;
  final double temperature;

  const HourlyWeather({
    required this.time,
    required this.windSpeed,
    required this.precipitation,
    required this.isDaylight,
    required this.cloudCover,
    required this.temperature,
  });

  bool get isPlayable => windSpeed < 15 && precipitation == 0;
}
