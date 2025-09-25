import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MealPlanController extends GetxController {
  var isLoading = true.obs;
  var mealsByDay = <String, List<Map<String, dynamic>>>{}.obs;
  var availableMeals = <Map<String, dynamic>>[].obs;

  final String apiUrl = 'https://www.themealdb.com/api/json/v1/1/filter.php?c=Beef';
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final AudioPlayer _audioPlayer = AudioPlayer();


  @override
  void onInit() {
    super.onInit();
    _initializeFirebase();
    _initializeNotifications();
    fetchMeals();
    _setupFirebaseMessaging();
    _scheduleJakartaAlarm();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize timezone
    tz.initializeTimeZones();
  }

  void _scheduleJakartaAlarm() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jakarta_alarm_channel',
      'Jakarta Alarm',
      channelDescription: 'Daily alarm for Jakarta time',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Jakarta Alarm',
      'It\'s 7:00 AM in Jakarta!',
      _nextInstanceOf7AMJakarta(),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf7AMJakarta() {
    tz.TZDateTime now = tz.TZDateTime.now(tz.getLocation('Asia/Jakarta'));
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.getLocation('Asia/Jakarta'),
      now.year,
      now.month,
      now.day,
      7, // 7 AM
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? 'You have a new update',
        );
      }
    });
  }

  void fetchMeals() async {
    isLoading(true);
    try {
      // Fetch meals from API
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> meals = List<Map<String, dynamic>>.from(data['meals']);
        availableMeals.assignAll(meals);

        // Organize meals by day of the week
        DateTime today = DateTime.now();
        List<String> daysOfWeek = [
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday'
        ];

        for (var day in daysOfWeek) {
          mealsByDay[day] = [];
        }

        for (int i = 0; i < meals.length && i < 7; i++) {
          String day = daysOfWeek[(today.weekday + i) % 7];
          mealsByDay[day]?.add(meals[i]);
        }

        // Schedule notifications and sync data to Firebase
        _scheduleDailyNotifications();
        await _saveMealsToFirestore(mealsByDay);
      } else {
        print("Failed to fetch meals: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching meals: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> _saveMealsToFirestore(Map<String, List<Map<String, dynamic>>> mealsByDay) async {
    final firestore = FirebaseFirestore.instance;
    for (var day in mealsByDay.keys) {
      await firestore.collection('meals').doc(day).set({
        'meals': mealsByDay[day],
      });
    }
  }

  Future<void> fetchMealsFromFirestore() async {
    final firestore = FirebaseFirestore.instance;
    isLoading(true);
    try {
      final daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      mealsByDay.clear();

      for (var day in daysOfWeek) {
        final snapshot = await firestore.collection('meals').doc(day).get();
        if (snapshot.exists) {
          mealsByDay[day] = List<Map<String, dynamic>>.from(snapshot.data()!['meals']);
        } else {
          mealsByDay[day] = [];
        }
      }
    } catch (e) {
      print("Error fetching meals from Firebase: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>?> fetchMealDetail(String mealId) async {
    try {
      final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId'));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['meals']?.first;
      }
    } catch (e) {
      print("Error fetching meal details: $e");
    }
    return null;
  }

  Future<void> addMeal(String day, Map<String, dynamic> meal) async {
    if (mealsByDay.containsKey(day)) {
      mealsByDay[day]?.add(meal);
      _showNotification("Meal Plan Update", "New meal added to $day");
      await _saveMealsToFirestore(mealsByDay);
      await fetchMealsFromFirestore();
    }
  }

  Future<void> updateMeal(String day, int index, Map<String, dynamic> updatedMeal) async {
    if (mealsByDay.containsKey(day) && mealsByDay[day]!.length > index) {
      mealsByDay[day]?[index] = updatedMeal;
      _showNotification("Meal Plan Update", "Meal updated for $day");
      await _saveMealsToFirestore(mealsByDay);
      await fetchMealsFromFirestore();
    }
  }

  Future<void> deleteMeal(String day, String mealId) async {
    if (mealsByDay.containsKey(day)) {
      mealsByDay[day]?.removeWhere((meal) => meal['idMeal'] == mealId);
      _showNotification("Meal Plan Update", "Meal deleted from $day");
      await _saveMealsToFirestore(mealsByDay);
      await fetchMealsFromFirestore();
    }
  }

  void _scheduleDailyNotifications() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('meal_reminder_channel', 'Meal Reminder',
            channelDescription: 'Daily reminder to check your meal plan',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true);

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    mealsByDay.forEach((day, meals) async {
      int dayIndex = _getDayIndex(day);
      String mealName = meals.isNotEmpty ? meals[0]['strMeal'] : "No meal scheduled";
      await flutterLocalNotificationsPlugin.zonedSchedule(
        dayIndex,
        "Meal Plan for $day",
        "Today's meal: $mealName",
        _nextInstanceOfDay(dayIndex),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    });
  }

  int _getDayIndex(String day) {
    switch (day) {
      case 'Sunday':
        return 0;
      case 'Monday':
        return 1;
      case 'Tuesday':
        return 2;
      case 'Wednesday':
        return 3;
      case 'Thursday':
        return 4;
      case 'Friday':
        return 5;
      case 'Saturday':
        return 6;
      default:
        return 0;
    }
  }

  tz.TZDateTime _nextInstanceOfDay(int day) {
    tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(days: 1));
    while (scheduledDate.weekday != day + 1) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  void _showNotification(String title, String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('meal_reminder_channel', 'Meal Reminder',
            channelDescription: 'Reminders for meal plan',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true);

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      message,
      platformChannelSpecifics,
    );

    // Play notification sound
    await _playNotificationSound();
  }

  Future<void> _playNotificationSound() async {
    try {
      // Path to the audio file in assets
      await _audioPlayer.play(AssetSource('audio/notification.mp3'));
    } catch (e) {
      print("Error playing audio: $e");
    }
  }
}
