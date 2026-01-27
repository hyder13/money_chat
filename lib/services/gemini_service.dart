import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../data/database/database.dart';
import '../data/models/models.dart';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  bool get isInitialized => _model != null;

  Future<void> initialize() async {
    final settings = Database.getSettings();
    if (!settings.hasApiKey) return;

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: settings.geminiApiKey!,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );

    _chatSession = _model!.startChat(history: await _buildHistory());
  }

  Future<List<Content>> _buildHistory() async {
    final history = <Content>[];

    // Add system instruction as first user message
    final systemPrompt = await _buildSystemPrompt();
    history.add(Content.model([TextPart(systemPrompt)]));

    // Add recent chat messages (last 30 days already filtered in DB)
    final messages = Database.chatMessages.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final msg in messages.take(50)) {
      if (msg.isUser) {
        history.add(Content.text(msg.content));
      } else {
        history.add(Content.model([TextPart(msg.content)]));
      }
    }

    return history;
  }

  Future<String> _buildSystemPrompt() async {
    final memoryBox = Database.userMemory;
    Map<String, dynamic> preferences = {};

    // Load category preferences from memory
    final prefMemory = memoryBox.values
        .where((m) => m.key == 'category_preferences')
        .firstOrNull;
    if (prefMemory != null) {
      try {
        preferences = jsonDecode(prefMemory.value);
      } catch (_) {}
    }

    return '''你是一個極簡風格的記帳助手。幫助用戶記錄支出、查詢記錄與刪除錯誤記錄。

你的任務：
1. 解析用戶輸入的消費描述，提取金額和類別
2. 如果用戶想查詢開銷（如「今天花了多少？」、「本週支出」），協助查詢
3. 如果用戶想刪除最後一筆記錄（如「刪除」、「記錯了」），協助刪除
4. 回覆要簡潔友善，用繁體中文

用戶的分類偏好（如能識別請優先使用）：
${jsonEncode(preferences)}

常用分類：餐飲、交通、娛樂、購物、日用、醫療、訂閱、其他

當用戶輸入一筆支出時，請用以下 JSON 格式回覆：
{"action": "add", "amount": 數字, "category": "分類", "description": "簡短描述"}

如果用戶要修改，請用：
{"action": "update", "amount": 新金額, "category": "新分類", "description": "新描述"}

如果用戶要查詢，請用：
{"action": "query", "target": "today" | "week" | "month", "category": "想查詢的分類，若無則為 null"}

如果用戶要刪除最後一筆，請用：
{"action": "delete", "target": "latest"}

如果是一般對話（不是記帳/查詢/刪除），正常用文字回覆即可。

記住：回覆要簡潔，像朋友聊天一樣自然。''';
  }

  Future<Map<String, dynamic>?> sendMessage(String message) async {
    if (!isInitialized || _chatSession == null) {
      return null;
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      final responseText = response.text ?? '';

      // Try to parse as JSON (expense entry)
      try {
        if (responseText.contains('{') && responseText.contains('}')) {
          final jsonStart = responseText.indexOf('{');
          final jsonEnd = responseText.lastIndexOf('}') + 1;
          final jsonStr = responseText.substring(jsonStart, jsonEnd);
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

          if (parsed.containsKey('action') && parsed.containsKey('amount')) {
            return {
              'type': 'expense',
              'data': parsed,
              'rawResponse': responseText,
            };
          }
          // Also handle query/delete which might not have 'amount'
          if (parsed.containsKey('action') &&
              (parsed['action'] == 'query' || parsed['action'] == 'delete')) {
            return {
              'type': 'expense',
              'data': parsed,
              'rawResponse': responseText,
            };
          }
        }
      } catch (_) {}

      // Regular text response
      return {'type': 'text', 'data': responseText};
    } catch (e) {
      return {'type': 'error', 'data': '發生錯誤：$e'};
    }
  }

  Future<void> updateCategoryPreference(String keyword, String category) async {
    final memoryBox = Database.userMemory;

    Map<String, dynamic> preferences = {};
    final existing = memoryBox.values
        .where((m) => m.key == 'category_preferences')
        .firstOrNull;

    if (existing != null) {
      try {
        preferences = jsonDecode(existing.value) as Map<String, dynamic>;
      } catch (_) {}

      preferences[keyword] = category;
      existing.value = jsonEncode(preferences);
      existing.updatedAt = DateTime.now();
      await existing.save();
    } else {
      preferences[keyword] = category;
      await memoryBox.add(
        UserMemory(key: 'category_preferences', value: jsonEncode(preferences)),
      );
    }
  }

  void reset() {
    _chatSession = null;
    _model = null;
  }
}
