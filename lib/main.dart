import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const ColorCashCrushApp());
}

class ColorCashCrushApp extends StatelessWidget {
  const ColorCashCrushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColorCashCrush',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        cardColor: Colors.white,
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      
      themeMode: ThemeMode.system,
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int points = 0;
  int cryptoTokens = 0;
  int watchedAdsCount = 0;
  final int requiredAdsToUnlock = 10;
  final int gridSize = 6;
  late List<Color> grid;
  
  final List<Color> gameColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // المعرف الاختباري الرسمي من جوجل للإعلانات المكافئة
  final String _adUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _generateGrid();
    _loadRewardedAd();
  }

  void _playSound(String soundName) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$soundName.mp3'));
    } catch (_) {}
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_isAdLoaded && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          _playSound('cash_win');
          setState(() {
            points += 100;
            watchedAdsCount++;
            cryptoTokens = (points / 100).floor() * 10;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("تمت مشاهدة الإعلان! المكافأة +100 نقطة ($watchedAdsCount/$requiredAdsToUnlock) 💰"),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
      _isAdLoaded = false;
      _loadRewardedAd();
    } else {
      _playSound('error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("جاري تحميل الإعلان الاختباري... حاول مجدداً")),
      );
      _loadRewardedAd();
    }
  }

  void _generateGrid() {
    final random = Random();
    grid = List.generate(
      gridSize * gridSize,
      (_) => gameColors[random.nextInt(gameColors.length)],
    );
  }

  void _onBlockClick(int index) {
    _playSound('pop');
    setState(() {
      grid[index] = gameColors[Random().nextInt(gameColors.length)];
      points += 10;
      cryptoTokens = (points / 100).floor() * 10;
    });
  }

  bool _isWithdrawalPeriod() {
    int currentDay = DateTime.now().day;
    return currentDay >= 25 && currentDay <= 30;
  }

  void _openWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("طلب سحب الأرباح 💰"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("رصيدك الحالي: $points نقطة ($cryptoTokens CRUSH)"),
            const SizedBox(height: 15),
            const TextField(
              decoration: InputDecoration(
                labelText: "أدخل عنوان محفظتك أو رقم الحساب",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("تم إرسال طلب السحب بنجاح! سيتم التحويل قريباً."),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("تأكيد السحب"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isWithdrawUnlocked = watchedAdsCount >= requiredAdsToUnlock;
    bool isWithdrawDateValid = _isWithdrawalPeriod();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ColorCashCrush', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black38 : Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("النقاط", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("$points", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
                Container(height: 35, width: 1, color: Colors.grey.withOpacity(0.3)),
                Column(
                  children: [
                    const Text("CRUSH Tokens", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("$cryptoTokens", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  ],
                ),
              ],
            ),
          ),

          Container(
            height: 320,
            width: 320,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridSize * gridSize,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onBlockClick(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: grid[index],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showRewardedAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAdLoaded ? Colors.deepPurple : Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_circle_fill, color: Colors.amber),
                  label: Text(
                    _isAdLoaded ? 'شاهد إعلان اختباري (+100 نقطة)' : 'جاري تحميل الإعلان...',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: (isWithdrawUnlocked && isWithdrawDateValid) ? _openWithdrawDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isWithdrawUnlocked && isWithdrawDateValid) ? Colors.green : Colors.grey[800],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    !isWithdrawUnlocked
                        ? "شاهد الإعلانات لفتح السحب ($watchedAdsCount/$requiredAdsToUnlock) 🔒"
                        : (!isWithdrawDateValid
                            ? "السحب متاح من 25 إلى 30 من الشهر فقط 🗓️"
                            : "اسحب أرباحك الآن 💰"),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
