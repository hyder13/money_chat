import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class Database {
  static const String _transactionsBox = 'transactions';
  static const String _chatMessagesBox = 'chat_messages';
  static const String _userMemoryBox = 'user_memory';
  static const String _settingsBox = 'settings';

  static late Box<TransactionModel> transactions;
  static late Box<ChatMessage> chatMessages;
  static late Box<UserMemory> userMemory;
  static late Box<AppSettings> settings;

  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${appDir.path}/money_chat');

    // Create directory if it doesn't exist
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    await Hive.initFlutter(dbDir.path);

    // Register adapters
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(UserMemoryAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    // Open boxes
    transactions = await Hive.openBox<TransactionModel>(_transactionsBox);
    chatMessages = await Hive.openBox<ChatMessage>(_chatMessagesBox);
    userMemory = await Hive.openBox<UserMemory>(_userMemoryBox);
    settings = await Hive.openBox<AppSettings>(_settingsBox);

    // Initialize default settings if not exists
    if (settings.isEmpty) {
      await settings.put('default', AppSettings());
    }
  }

  static AppSettings getSettings() {
    return settings.get('default') ?? AppSettings();
  }

  static Future<void> saveSettings(AppSettings appSettings) async {
    await settings.put('default', appSettings);
  }

  // Clean up old chat messages (keep only last 30 days)
  static Future<void> cleanupOldMessages() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final keysToDelete = <dynamic>[];

    for (var i = 0; i < chatMessages.length; i++) {
      final message = chatMessages.getAt(i);
      if (message != null && message.timestamp.isBefore(thirtyDaysAgo)) {
        keysToDelete.add(chatMessages.keyAt(i));
      }
    }

    for (final key in keysToDelete) {
      await chatMessages.delete(key);
    }
  }
}
