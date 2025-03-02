import 'package:flutter_local_notifications/flutter_local_notifications.dart';
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
Future<void> initNotifications() async {

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  final bool? grantedNotificationPermission = await androidImplementation?.requestNotificationsPermission();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('launch_background');

  const DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
Future<void> showNotification(String texto, int id) async {
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'channel id',
      'channel name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker'
  );
  const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
  await flutterLocalNotificationsPlugin.show(
    id,
    'Carnaval',
    texto,
    notificationDetails,
    payload: 'item x',
  );
}