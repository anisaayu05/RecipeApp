import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class RatingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  var averageRating = 0.0.obs;
  var totalRatings = 0.obs;
  var reviews = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFirebase();
    _initializeNotifications();
    _setupFirebaseMessaging();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification payload: ${response.payload}');
        // Handle navigation or any other action here based on the payload.
      },
    );
  }

  void _setupFirebaseMessaging() {
    _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? 'You have a new update',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Handle navigation or any other logic here when the app is opened from a notification.
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from a terminated state by a notification');
        // Handle navigation or any other logic here when the app is opened from a terminated state.
      }
    });
  }

  void fetchRatingsData(String mealId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('mealId', isEqualTo: mealId)
          .get();

      double totalScore = 0;
      int count = 0;
      var fetchedReviews = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalScore += data['rating'];
        count++;
        fetchedReviews.add({
          'id': doc.id,
          'rating': data['rating'],
          'review': data['review'],
          'userEmail': data['userEmail'],
          'timestamp': data['timestamp'],
        });
      }

      averageRating.value = count > 0 ? totalScore / count : 0.0;
      totalRatings.value = count;
      reviews.value = fetchedReviews;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch ratings. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> submitReview(
      String mealId, int rating, String review, BuildContext context) async {
    final User? user = _auth.currentUser;
    final userEmail = user?.email;

    if (userEmail != null && rating > 0 && review.isNotEmpty) {
      try {
        await _firestore.collection('reviews').add({
          'mealId': mealId,
          'rating': rating,
          'review': review,
          'userEmail': userEmail,
          'timestamp': Timestamp.now(),
        });
        fetchRatingsData(mealId);
        Navigator.of(context).pop(); // Close modal after submission
        _showNotification(
          'Success',
          'Your review has been added.',
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to add review. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> updateReview(String reviewId, int newRating, String newReview,
      BuildContext context) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'rating': newRating,
        'review': newReview,
        'timestamp': Timestamp.now(),
      });
      fetchRatingsData(reviewId);
      Navigator.of(context).pop(); // Close modal after updating
      _showNotification(
        'Success',
        'Your review has been updated.',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteReview(String reviewId, BuildContext context) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      fetchRatingsData(reviewId);
      Navigator.of(context).pop(); // Close modal after deletion
      _showNotification(
        'Success',
        'Your review has been deleted.',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showNotification(String title, String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('rating_channel', 'Rating Notifications',
            channelDescription: 'Notifications for rating updates',
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
  }
}
