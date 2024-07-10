// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'native_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NativeItemAdapter extends TypeAdapter<NativeItem> {
  @override
  final int typeId = 0;

  @override
  NativeItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NativeItem(
      bottom: (fields[0] as List?)?.cast<Bottom>(),
    );
  }

  @override
  void write(BinaryWriter writer, NativeItem obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.bottom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BottomAdapter extends TypeAdapter<Bottom> {
  @override
  final int typeId = 1;

  @override
  Bottom read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bottom(
      title: fields[0] as String?,
      icon: fields[1] as String?,
      uRL: fields[2] as String?,
      id: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Bottom obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.icon)
      ..writeByte(2)
      ..write(obj.uRL)
      ..writeByte(3)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BottomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
