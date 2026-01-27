// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_memory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserMemoryAdapter extends TypeAdapter<UserMemory> {
  @override
  final int typeId = 2;

  @override
  UserMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserMemory(
      key: fields[0] as String,
      value: fields[1] as String,
      updatedAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserMemory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMemoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
