import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

// Biến toàn cục lưu API Key đọc từ file API.md
String apiKey = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    apiKey = (await rootBundle.loadString('API.md')).trim();
  } catch (e) {
    debugPrint('Không thể đọc file API.md: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dự báo thời tiết',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// =============================================================================
// HELPER FUNCTIONS: XỬ LÝ ICON & BẢNG MÀU THEO THỜI TIẾT
// =============================================================================

IconData getWeatherIcon(String? condition) {
  if (condition == null) return Icons.wb_sunny_rounded;
  switch (condition.toLowerCase()) {
    case 'clear':
      return Icons.wb_sunny_rounded;
    case 'clouds':
      return Icons.cloud_rounded;
    case 'rain':
    case 'drizzle':
      return Icons.water_drop_rounded;
    case 'thunderstorm':
      return Icons.thunderstorm_rounded;
    case 'snow':
      return Icons.ac_unit_rounded;
    case 'mist':
    case 'fog':
    case 'haze':
      return Icons.filter_drama_rounded;
    default:
      return Icons.wb_cloudy_rounded;
  }
}

Color getWeatherThemeColor(String? condition) {
  if (condition == null) return Colors.orange;
  switch (condition.toLowerCase()) {
    case 'clear':
      return Colors.orangeAccent;
    case 'clouds':
      return Colors.blueGrey;
    case 'rain':
    case 'drizzle':
      return Colors.blue;
    case 'thunderstorm':
      return Colors.deepPurple;
    case 'snow':
      return Colors.lightBlue;
    default:
      return Colors.teal;
  }
}

List<Color> getWeatherGradient(String? condition) {
  if (condition == null) {
    return [const Color(0xFF2980B9), const Color(0xFF6DD5FA)];
  }
  switch (condition.toLowerCase()) {
    case 'clear':
      return [const Color(0xFFFF7E5F), const Color(0xFFFEB47B)]; // Cam nắng ấm
    case 'clouds':
      return [const Color(0xFF616161), const Color(0xFF9BC5C3)]; // Xám mây
    case 'rain':
    case 'drizzle':
      return [const Color(0xFF1F1C2C), const Color(0xFF928DAB)]; // Xanh xám mưa
    case 'thunderstorm':
      return [const Color(0xFF0F2027), const Color(0xFF2C5364)]; // Đêm dông bão
    case 'snow':
      return [const Color(0xFF83A4D4), const Color(0xFFB6FBFF)]; // Băng tuyết
    default:
      return [const Color(0xFF2980B9), const Color(0xFF6DD5FA)];
  }
}

// =============================================================================
// MÀN HÌNH CHÍNH (HOME SCREEN)
// =============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _suggestions = [
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Tokyo',
    'Paris',
    'New York',
  ];

  final List<String> _featuredCities = [
    'Hà Nội',
    'Thành phố Hồ Chí Minh',
    'Đà Nẵng',
    'Tokyo',
    'Paris',
    'Thành phố New York',
  ];

  final Map<String, dynamic> _weatherData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedCitiesWeather();
  }

  Future<void> _loadFeaturedCitiesWeather() async {
    for (String city in _featuredCities) {
      final data = await _fetchWeatherData(city);
      if (data != null) {
        setState(() {
          _weatherData[city] = data;
        });
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchWeatherData(String cityName) async {
    if (apiKey.isEmpty) {
      debugPrint('Chưa có API Key!');
      return null;
    }

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric&lang=vi',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi kết nối API: $e');
    }
    return null;
  }

  void _openDetailScreen(String cityName, Map<String, dynamic>? data) async {
    Map<String, dynamic>? detailData = data;

    if (detailData == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      detailData = await _fetchWeatherData(cityName);
      if (mounted) Navigator.pop(context);
    }

    if (detailData != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(weatherData: detailData!),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải dữ liệu thời tiết cho thành phố này!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '2224801030280 - Dự báo thời tiết',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh tìm kiếm + Autocomplete
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _suggestions.where((String option) {
                        return option.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    onSelected: (String selection) {
                      _openDetailScreen(selection, null);
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) => searchController.text = val,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên thành phố (vd: Hà Nội)...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                          );
                        },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      if (searchController.text.isNotEmpty) {
                        _openDetailScreen(searchController.text, null);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Thành phố nổi bật',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // Danh sách thành phố nổi bật
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _featuredCities.length,
                      itemBuilder: (context, index) {
                        String city = _featuredCities[index];
                        var data = _weatherData[city];

                        String mainCondition = data != null
                            ? data['weather'][0]['main']
                            : '';
                        IconData dynamicIcon = getWeatherIcon(mainCondition);
                        Color iconColor = getWeatherThemeColor(mainCondition);

                        String temp = data != null
                            ? '${(data['main']['temp'] as num).toDouble().toStringAsFixed(1)}°C'
                            : '--°C';

                        String description = data != null
                            ? data['weather'][0]['description']
                            : 'Đang nạp...';

                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            // ICON ĐỘNG PHÍA TRƯỚC TÊN THÀNH PHỐ
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                dynamicIcon,
                                color: iconColor,
                                size: 26,
                              ),
                            ),
                            title: Text(
                              city,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              description,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Text(
                              temp,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            onTap: () => _openDetailScreen(city, data),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MÀN HÌNH CHI TIẾT VỚI HIỆU ỨNG THỜI TIẾT DYNAMIC (DETAIL SCREEN)
// =============================================================================

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> weatherData;

  const DetailScreen({super.key, required this.weatherData});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Animation controller chạy liên tục cho hiệu ứng thời tiết
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String city = widget.weatherData['name'] ?? 'Chi tiết';
    double temp = (widget.weatherData['main']['temp'] as num).toDouble();
    double feelsLike = (widget.weatherData['main']['feels_like'] as num)
        .toDouble();
    int humidity = widget.weatherData['main']['humidity'];
    int pressure = widget.weatherData['main']['pressure'];
    double windSpeed = (widget.weatherData['wind']['speed'] as num).toDouble();

    String mainCondition = widget.weatherData['weather'][0]['main'] ?? '';
    String description =
        (widget.weatherData['weather'][0]['description'] as String)
            .toUpperCase();

    List<Color> gradientColors = getWeatherGradient(mainCondition);
    IconData weatherIcon = getWeatherIcon(mainCondition);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Phông nền Gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
          ),

          // 2. Lớp hiệu ứng Động (Mưa, Mây, Nắng...)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: WeatherEffectPainter(
                  condition: mainCondition,
                  progress: _animationController.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

          // 3. Nội dung thông tin thời tiết
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        city,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Biểu tượng thời tiết lớn sinh động
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          double scale = 1.0;
                          if (mainCondition.toLowerCase() == 'clear') {
                            scale =
                                1.0 +
                                0.08 *
                                    math.sin(
                                      _animationController.value * 2 * math.pi,
                                    );
                          }
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                weatherIcon,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      Text(
                        '${temp.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),

                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.2,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Bảng chi tiết
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDetailTile(
                                    icon: Icons.thermostat,
                                    label: 'Cảm giác',
                                    value: '${feelsLike.toStringAsFixed(1)}°C',
                                  ),
                                  _buildDetailTile(
                                    icon: Icons.water_drop,
                                    label: 'Độ ẩm',
                                    value: '$humidity%',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDetailTile(
                                    icon: Icons.air,
                                    label: 'Sức gió',
                                    value: '$windSpeed m/s',
                                  ),
                                  _buildDetailTile(
                                    icon: Icons.speed,
                                    label: 'Áp suất',
                                    value: '$pressure hPa',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: VẼ HIỆU ỨNG THỜI TIẾT CHUYỂN ĐỘNG (MƯA / MÂY / NẮNG)
// =============================================================================

class WeatherEffectPainter extends CustomPainter {
  final String condition;
  final double progress;

  WeatherEffectPainter({required this.condition, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final String type = condition.toLowerCase();

    // 1. HIỆU ỨNG TRỜI MƯA (Rain / Drizzle / Thunderstorm)
    if (type == 'rain' || type == 'drizzle' || type == 'thunderstorm') {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final math.Random random = math.Random(42); // Seed cố định vị trí hạt mưa
      for (int i = 0; i < 40; i++) {
        double startX = random.nextDouble() * size.width;
        double startY = random.nextDouble() * size.height;

        // Cho hạt mưa di chuyển đi xuống theo progress
        double currentY = (startY + progress * size.height) % size.height;
        double currentX = startX - (progress * 20); // Mưa hơi chéo

        canvas.drawLine(
          Offset(currentX, currentY),
          Offset(currentX - 3, currentY + 15),
          paint,
        );
      }
    }
    // 2. HIỆU ỨNG TRỜI MÂY (Clouds / Fog / Mist)
    else if (type == 'clouds' || type == 'mist' || type == 'fog') {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.08);

      double offsetX = progress * size.width;

      // Đám mây 1
      canvas.drawCircle(
        Offset((offsetX) % (size.width + 200) - 100, size.height * 0.25),
        80,
        paint,
      );
      canvas.drawCircle(
        Offset((offsetX + 60) % (size.width + 200) - 100, size.height * 0.22),
        100,
        paint,
      );

      // Đám mây 2
      canvas.drawCircle(
        Offset(
          (offsetX * 0.5 + 150) % (size.width + 200) - 100,
          size.height * 0.45,
        ),
        60,
        paint,
      );
    }
    // 3. HIỆU ỨNG TRỜI NẮNG (Clear) - Dải hào quang
    else if (type == 'clear') {
      final paint = Paint()
        ..color = Colors.yellowAccent.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill;

      double radius = 180 + 20 * math.sin(progress * 2 * math.pi);
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.38),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeatherEffectPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.condition != condition;
  }
}
