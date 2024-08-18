import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Firebase initialized successfully");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smoke Detector',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const HomePage(
      {super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('sensor_data');
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isSmokeDetected = false;
  int _currentSensorValue = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenToDatabase();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeNotifications() {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenToDatabase() {
  _database.onValue.listen((event) {
    print("Received database event");
    if (event.snapshot.value == null) {
      print("Snapshot value is null");
      return;
    }

    try {
      print("Raw snapshot value: ${event.snapshot.value}");
      var data = event.snapshot.value as Map<dynamic, dynamic>;
      print("Data as map: $data");

      if (data.containsKey('sensor_value')) {
        setState(() {
          _currentSensorValue = data['sensor_value'] as int? ?? 0;
          _isSmokeDetected = (_currentSensorValue > 500);
        });
        print("Current sensor value: $_currentSensorValue");
        print("Is smoke detected: $_isSmokeDetected");

        if (_isSmokeDetected) {
          _showNotification();
        }
      } else {
        print("'sensor_value' key not found in data");
      }
    } catch (e) {
      print('Error processing data: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
  }, onError: (error) {
    print('Error listening to database: $error');
  });
}
  Future<void> _showNotification() async {
  try {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'smoke_detector_channel',
      'Smoke Detector Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Smoke Detected!',
      'Sensor value: $_currentSensorValue',
      platformChannelSpecifics,
    );
    print("Notification shown successfully");
  } catch (e) {
    print("Error showing notification: $e");
    print("Error stack trace: ${StackTrace.current}");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smoke Detector'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isSmokeDetected
                ? Colors.red.withOpacity(0.2)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + 0.1 * _animationController.value,
                    child: _isSmokeDetected
                        ? Lottie.asset(
                            'assets/json/smoke.json',
                            width: 200,
                            height: 200,
                          )
                        : Lottie.asset(
                            'assets/json/no_smoke.json',
                            width: 200,
                            height: 200,
                          ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                _isSmokeDetected ? 'Smoke Detected!' : 'No Smoke Detected',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isSmokeDetected ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Current Sensor Value: $_currentSensorValue',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Add functionality to reset or test the sensor
                },
                child: const Text('Reset Sensor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
