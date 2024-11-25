import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gestion_caisse_flutter/models/todo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationManager {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationManager({required this.flutterLocalNotificationsPlugin});

  Future<bool> scheduleNotifications(Todo todo) async {
    try {
      if (todo.dueDate == null || todo.notificationTime == null) {
        print('Invalid todo: missing due date or notification time');
        return false;
      }

      // Get current time in the correct timezone
      final now = tz.TZDateTime.now(tz.local);

      // Create the due date time by combining the date and notification time
      final dueDateTime = tz.TZDateTime(
        tz.local,
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
        todo.notificationTime!.hour,
        todo.notificationTime!.minute,
      );

      // If the due date is in the past, return false
      if (dueDateTime.isBefore(now)) {
        print('Cannot schedule notification for past date: $dueDateTime');
        return false;
      }

      // Calculate notification times (3 days, 2 days, 1 day before, and day of)
      final notificationTimes = [
        _createScheduledDate(dueDateTime.subtract(const Duration(days: 3))),
        _createScheduledDate(dueDateTime.subtract(const Duration(days: 2))),
        _createScheduledDate(dueDateTime.subtract(const Duration(days: 1))),
        _createScheduledDate(dueDateTime),
      ].where((date) => date.isAfter(now)).toList();

      if (notificationTimes.isEmpty) {
        print('No valid future notification times available');
        return false;
      }

      // Notification details
      const androidDetails = AndroidNotificationDetails(
        'todo_channel',
        'Tâches',
        channelDescription: 'Notifications pour les tâches',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Schedule each notification
      for (var (index, scheduleTime) in notificationTimes.indexed) {
        final timeUntilDue = _getTimeUntilDue(scheduleTime, dueDateTime);
        final notificationId = _generateNotificationId(todo.id, index);

        // Cancel any existing notification with this ID
        await flutterLocalNotificationsPlugin.cancel(notificationId);

        // Schedule new notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          'Rappel: ${todo.description}',
          'Cette tâche est due $timeUntilDue',
          scheduleTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        print('Notification scheduled for: ${scheduleTime.toString()}');
      }

      // Save notification information
      await _savePendingNotification(todo, notificationTimes);
      return true;
    } catch (e, stackTrace) {
      print('Error scheduling notifications: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Helper method to create a valid scheduled date
  tz.TZDateTime _createScheduledDate(tz.TZDateTime dateTime) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );

    // If the date is in the past, return a date far in the future
    // This will be filtered out by the isAfter(now) check
    if (scheduledDate.isBefore(now)) {
      return now.add(const Duration(days: 365));
    }

    return scheduledDate;
  }

  // Generate a unique, consistent notification ID
  int _generateNotificationId(String todoId, int index) {
    return todoId.hashCode + index;
  }

  String _getTimeUntilDue(
      tz.TZDateTime notificationTime, tz.TZDateTime dueDateTime) {
    final difference = dueDateTime.difference(notificationTime);
    if (difference.inDays == 0) {
      return "aujourd'hui";
    } else if (difference.inDays == 1) {
      return "demain";
    } else {
      return "dans ${difference.inDays} jours";
    }
  }

  Future<void> _savePendingNotification(
      Todo todo, List<tz.TZDateTime> notificationTimes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString('pending_notifications');
      List<Map<String, dynamic>> notifications = [];

      if (existingData != null) {
        notifications =
            List<Map<String, dynamic>>.from(json.decode(existingData));
      }

      // Remove any existing notifications for this todo
      notifications
          .removeWhere((notification) => notification['id'] == todo.id);

      // Add new notification data
      notifications.add({
        'id': todo.id,
        'description': todo.description,
        'dueDate': todo.dueDate!.toIso8601String(),
        'notificationTimes':
            notificationTimes.map((time) => time.toIso8601String()).toList(),
      });

      await prefs.setString(
          'pending_notifications', json.encode(notifications));
    } catch (e) {
      print('Error saving notification data: $e');
    }
  }

  Future<void> cancelNotifications(String todoId) async {
    try {
      // Cancel all existing notifications for this todo
      for (int i = 0; i < 4; i++) {
        await flutterLocalNotificationsPlugin
            .cancel(_generateNotificationId(todoId, i));
      }

      // Remove saved notification data
      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString('pending_notifications');
      if (existingData != null) {
        final notifications =
            List<Map<String, dynamic>>.from(json.decode(existingData));
        notifications
            .removeWhere((notification) => notification['id'] == todoId);
        await prefs.setString(
            'pending_notifications', json.encode(notifications));
      }
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }
}
