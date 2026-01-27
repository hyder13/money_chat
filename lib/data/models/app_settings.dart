import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 3)
class AppSettings extends HiveObject {
  @HiveField(0)
  String? geminiApiKey;

  @HiveField(1)
  late String theme; // 'light', 'dark', 'system'

  @HiveField(2)
  late String currency; // Reserved for future use

  AppSettings({
    this.geminiApiKey,
    this.theme = 'system',
    this.currency = 'TWD',
  });

  bool get hasApiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;
}
