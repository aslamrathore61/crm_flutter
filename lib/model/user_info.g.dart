// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserInfoAdapter extends TypeAdapter<UserInfo> {
  @override
  final int typeId = 5;

  @override
  UserInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserInfo(
      token: fields[0] as String?,
      name: fields[1] as String?,
      department: fields[2] as String?,
      status: fields[3] as int?,
      message: fields[4] as String?,
      available: fields[5] as bool?,
      agentUuid: fields[6] as String?,
      profileImageUrl: fields[7] as String?,
      clockedIn: fields[8] as bool?,
      loggedInHrs: fields[9] as String?,
      teamLead: fields[10] as bool?,
      type: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserInfo obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.token)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.department)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.available)
      ..writeByte(6)
      ..write(obj.agentUuid)
      ..writeByte(7)
      ..write(obj.profileImageUrl)
      ..writeByte(8)
      ..write(obj.clockedIn)
      ..writeByte(9)
      ..write(obj.loggedInHrs)
      ..writeByte(10)
      ..write(obj.teamLead)
      ..writeByte(11)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
