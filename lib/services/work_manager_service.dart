import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class WorkManagerService {
  static const String taskName = "todoNotificationTask";

  /*static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }*/

  static Future<void> initialize() async {
    // Initialiser les notifications locales avant Workmanager
    await _initializeNotifications();
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  static Future<void> _initializeNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Configuration Android avec support des emojis
    const androidSettings = AndroidInitializationSettings('@mipmap/logo');
    const initSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        // Gérer l'interaction avec la notification ici
      },
    );
  }

  static Future<void> scheduleNotification({
    required String todoId,
    required String todoDescription,
    required DateTime dueDate,
    TimeOfDay? notificationTime,
  }) async {
    // Convertir la TimeOfDay en DateTime ou utiliser 8h par défaut
    const defaultTime = TimeOfDay(hour: 8, minute: 0);
    final timeToUse = notificationTime ?? defaultTime;

    // Calculer les dates de notification
    final dueDateWithTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      timeToUse.hour,
      timeToUse.minute,
    );

    final notificationDates = [
      dueDateWithTime.subtract(const Duration(days: 3)),
      dueDateWithTime.subtract(const Duration(days: 2)),
      dueDateWithTime.subtract(const Duration(days: 1)),
      dueDateWithTime,
    ];

    // Sauvegarder les informations de la tâche avec l'heure de notification
    await _saveTodoNotificationInfo(
      todoId: todoId,
      description: todoDescription,
      dueDate: dueDate,
      notificationTime: timeToUse,
    );

    // Programmer les notifications pour chaque date
    for (var date in notificationDates) {
      if (date.isAfter(DateTime.now())) {
        final uniqueId = '${todoId}_${date.millisecondsSinceEpoch}';

        // Créer une DateTime avec l'heure de notification spécifique
        final scheduledDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          timeToUse.hour,
          timeToUse.minute,
        );

        await Workmanager().registerOneOffTask(
          uniqueId,
          taskName,
          initialDelay: scheduledDateTime.difference(DateTime.now()),
          inputData: {
            'todoId': todoId,
            'description': todoDescription,
            'dueDate': dueDate.toIso8601String(),
            'notificationDate': date.toIso8601String(),
            'notificationHour': timeToUse.hour,
            'notificationMinute': timeToUse.minute,
          },
          constraints: Constraints(
            networkType: NetworkType.not_required,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
        );
      }
    }
  }

  // Ajout de la méthode manquante _saveTodoNotificationInfo
  static Future<void> _saveTodoNotificationInfo({
    required String todoId,
    required String description,
    required DateTime dueDate,
    required TimeOfDay notificationTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationInfo = {
        'todoId': todoId,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'notificationTime':
            '${notificationTime.hour}:${notificationTime.minute}',
      };
      await prefs.setString(
          'todo_notification_$todoId', jsonEncode(notificationInfo));
    } catch (e) {
      print(
          'Erreur lors de la sauvegarde des informations de notification: $e');
      // On ne relance pas l'erreur pour ne pas interrompre le flux principal
    }
  }

  static Future<void> cancelNotifications(String todoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskIds = prefs.getStringList('task_ids_$todoId') ?? [];

      // Cancel each task
      for (final taskId in taskIds) {
        await Workmanager().cancelByUniqueName(taskId);
      }

      // Remove saved task IDs
      await prefs.remove('task_ids_$todoId');
      await prefs.remove('todo_notification_$todoId');
    } catch (e) {
      print('Erreur lors de l\'annulation des notifications: $e');
    }
  }
}

// Callback global modifié pour WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == WorkManagerService.taskName) {
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();

        // Configuration Android spécifique pour les notifications avec support emoji
        const androidDetails = AndroidNotificationDetails(
          'todo_channel',
          'Rappels de tâches',
          channelDescription: 'Notifications pour les tâches à venir',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation:
              BigTextStyleInformation(''), // Permet le rendu des emojis
          icon: '@mipmap/logo', // Utiliser l'icône de l'application
          largeIcon:
              DrawableResourceAndroidBitmap('@mipmap/logo'), // Icône large
          enableLights: true,
          color: Colors.blue, // Couleur de la LED de notification
          playSound: true,
          enableVibration: true,
        );

        // Extraire les données
        final todoId = inputData?['todoId'] as String;
        final description = inputData?['description'] as String;
        final dueDate = DateTime.parse(inputData?['dueDate'] as String);
        final notificationDate =
            DateTime.parse(inputData?['notificationDate'] as String);
        final notificationHour = inputData?['notificationHour'] as int;
        final notificationMinute = inputData?['notificationMinute'] as int;

        final scheduledTime = DateTime(
          notificationDate.year,
          notificationDate.month,
          notificationDate.day,
          notificationHour,
          notificationMinute,
        );

        final now = DateTime.now();
        if (now.difference(scheduledTime).inMinutes.abs() <= 5) {
          final daysUntilDue = dueDate.difference(notificationDate).inDays;

          // Messages avec emojis garantis d'être affichés correctement
          String message;
          if (daysUntilDue == 0) {
            message = "📌 La tâche '$description' est due aujourd'hui! 🚨";
          } else {
            message =
                "📅 La tâche '$description' est due dans $daysUntilDue jours. ⏰ Préparez-vous!";
          }

          const notificationDetails =
              NotificationDetails(android: androidDetails);

          await flutterLocalNotificationsPlugin.show(
            todoId.hashCode,
            '📋 Rappel de tâche',
            message,
            notificationDetails,
          );
        }
      }
      return true;
    } catch (e) {
      print('Erreur dans le callback WorkManager: $e');
      return false;
    }
  });
}

/*void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == WorkManagerService.taskName) {
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();

        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidSettings);
        await flutterLocalNotificationsPlugin.initialize(initSettings);

        // Extraire les données avec l'heure de notification
        final todoId = inputData?['todoId'] as String;
        final description = inputData?['description'] as String;
        final dueDate = DateTime.parse(inputData?['dueDate'] as String);
        final notificationDate =
            DateTime.parse(inputData?['notificationDate'] as String);
        final notificationHour = inputData?['notificationHour'] as int;
        final notificationMinute = inputData?['notificationMinute'] as int;

        // Créer la DateTime exacte pour la notification
        final scheduledTime = DateTime(
          notificationDate.year,
          notificationDate.month,
          notificationDate.day,
          notificationHour,
          notificationMinute,
        );

        // Vérifier si c'est le bon moment pour envoyer la notification
        final now = DateTime.now();
        if (now.difference(scheduledTime).inMinutes.abs() <= 5) {
          // 5 minutes de tolérance
          // Calculer le nombre de jours restants
          final daysUntilDue = dueDate.difference(notificationDate).inDays;

          // Préparer le message de notification
          String message;
          if (daysUntilDue == 0) {
            message =
                "📌 La tâche '$description' est due **aujourd'hui**! 🕒 🚨";
          } else {
            message =
                "📅 La tâche '$description' est due dans $daysUntilDue jours 🗓️. 🕒 Préparez-vous!";
          }

          // Afficher la notification
          const androidDetails = AndroidNotificationDetails(
            'todo_channel',
            'Rappels de tâches',
            channelDescription: 'Notifications pour les tâches à venir',
            importance: Importance.high,
            priority: Priority.high,
          );

          const notificationDetails =
              NotificationDetails(android: androidDetails);

          await flutterLocalNotificationsPlugin.show(
            todoId.hashCode,
            'Rappel de tâche',
            message,
            notificationDetails,
          );
        }
      }
      return true;
    } catch (e) {
      print('Erreur dans le callback WorkManager: $e');
      return false;
    }
  });
}*/
