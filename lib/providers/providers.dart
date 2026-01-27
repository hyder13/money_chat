import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/database.dart';
import '../data/models/models.dart';
import '../services/gemini_service.dart';

const _uuid = Uuid();

// Gemini Service Provider
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

// Chat Messages Provider
final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
        ChatMessagesNotifier.new);

class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return _loadMessages();
  }

  List<ChatMessage> _loadMessages() {
    final messages = Database.chatMessages.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<void> addMessage(String content, String role) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      role: role,
      content: content,
    );

    await Database.chatMessages.add(message);
    state = [...state, message];
  }

  Future<void> clearAll() async {
    await Database.chatMessages.clear();
    state = [];
  }
}

// Transactions Provider
final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<TransactionModel>>(
        TransactionsNotifier.new);

class TransactionsNotifier extends Notifier<List<TransactionModel>> {
  @override
  List<TransactionModel> build() {
    return _loadTransactions();
  }

  List<TransactionModel> _loadTransactions() {
    final transactions = Database.transactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<void> addTransaction({
    required double amount,
    required String category,
    required String description,
    DateTime? date,
  }) async {
    final transaction = TransactionModel(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      description: description,
      date: date ?? DateTime.now(),
    );

    await Database.transactions.add(transaction);
    state = [transaction, ...state];
  }

  Future<void> updateLatest({
    double? amount,
    String? category,
    String? description,
  }) async {
    if (state.isEmpty) return;

    final latest = state.first;
    if (amount != null) latest.amount = amount;
    if (category != null) latest.category = category;
    if (description != null) latest.description = description;

    await latest.save();
    state = [latest, ...state.skip(1)];
  }

  List<TransactionModel> getByMonth(int year, int month) {
    return state.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();
  }

  Map<String, double> getCategoryTotals(int year, int month) {
    final monthTransactions = getByMonth(year, month);
    final totals = <String, double>{};

    for (final t in monthTransactions) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }

    return totals;
  }

  List<MapEntry<DateTime, double>> getMonthlyTrend(
      {String? category, int months = 6}) {
    final now = DateTime.now();
    final trend = <MapEntry<DateTime, double>>[];

    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTotal = state
          .where((t) =>
              t.date.year == month.year &&
              t.date.month == month.month &&
              (category == null || t.category == category))
          .fold<double>(0, (sum, t) => sum + t.amount);
      trend.add(MapEntry(month, monthTotal));
    }

    return trend;
  }
}

// Settings Provider
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return Database.getSettings();
  }

  Future<void> updateApiKey(String? apiKey) async {
    state.geminiApiKey = apiKey;
    await Database.saveSettings(state);
    state = Database.getSettings();
  }

  Future<void> updateTheme(String theme) async {
    state.theme = theme;
    await Database.saveSettings(state);
    state = Database.getSettings();
  }
}
