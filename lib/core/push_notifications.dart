import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'app_state.dart'; // AppLang
import '../firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

/// Maneja permisos, token y suscripción a topics de idioma en FCM.
class PushNotifications {
  PushNotifications._();
  static final PushNotifications instance = PushNotifications._();

  static const _prefKeyLastTopic = 'push_last_topic';
  String? _currentTopic;

  /// Debe llamarse al inicio de la app, pasando el idioma guardado.
  Future<void> init(AppLang lang) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (kDebugMode) {
      final token = await FirebaseMessaging.instance.getToken();
      // Handy para verificar en logcat/flutter logs.
      // ignore: avoid_print
      print('[FCM] settings=$settings token=$token');
    }
    await _syncLanguageTopic(lang);

    FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      // Si cambia el token garantizamos que sigue suscripto al topic de idioma.
      final topic = _currentTopic ?? await _loadLastTopic();
      if (topic != null && topic.isNotEmpty) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      }
    });
  }

  /// Se llama cada vez que cambia el idioma de la app.
  Future<void> onLanguageChanged(AppLang lang) async {
    await _syncLanguageTopic(lang);
  }

  Future<void> _syncLanguageTopic(AppLang lang) async {
    final topic = _topicForLang(lang);
    final prefs = await SharedPreferences.getInstance();
    final prev = prefs.getString(_prefKeyLastTopic);

    if (prev != null && prev != topic) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(prev);
    }
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    await prefs.setString(_prefKeyLastTopic, topic);
    _currentTopic = topic;
  }

  Future<String?> _loadLastTopic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyLastTopic);
  }

  String _topicForLang(AppLang lang) {
    switch (lang) {
      case AppLang.es:
        return 'lang-es';
      case AppLang.en:
        return 'lang-en';
      case AppLang.pt:
        return 'lang-pt';
      case AppLang.it:
        return 'lang-it';
    }
  }
}

/// Handler obligatorio para mensajes en background/terminated.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
