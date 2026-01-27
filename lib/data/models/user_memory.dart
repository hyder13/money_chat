import 'package:hive/hive.dart';

part 'user_memory.g.dart';

@HiveType(typeId: 2)
class UserMemory extends HiveObject {
  @override
  @HiveField(0)
  late String key;

  @HiveField(1)
  late String value; // JSON string

  @HiveField(2)
  late DateTime updatedAt;

  UserMemory({required this.key, required this.value, DateTime? updatedAt})
    : updatedAt = updatedAt ?? DateTime.now();
}
