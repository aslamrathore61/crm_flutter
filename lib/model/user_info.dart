import 'package:hive/hive.dart';

part 'user_info.g.dart';


@HiveType(typeId: 5) // Assign a unique typeId for this Hive class
class UserInfo extends HiveObject {
  @HiveField(0)
  String? token;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? department;

  @HiveField(3)
  int? status;

  @HiveField(4)
  String? message;

  @HiveField(5)
  bool? available;

  @HiveField(6)
  String? agentUuid;

  @HiveField(7)
  String? profileImageUrl;

  @HiveField(8)
  bool? clockedIn;

  @HiveField(9)
  String? loggedInHrs;

  @HiveField(10)
  bool? teamLead;

  @HiveField(11)
  String? type;

  UserInfo({
    this.token,
    this.name,
    this.department,
    this.status,
    this.message,
    this.available,
    this.agentUuid,
    this.profileImageUrl,
    this.clockedIn,
    this.loggedInHrs,
    this.teamLead,
    this.type,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      token: json['token'],
      name: json['name'],
      department: json['department'],
      status: json['status'],
      message: json['message'],
      available: json['available'],
      agentUuid: json['agentUuid'],
      profileImageUrl: json['profileImageUrl'],
      clockedIn: json['clockedIn'],
      loggedInHrs: json['loggedInHrs'],
      teamLead: json['teamLead'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'name': name,
      'department': department,
      'status': status,
      'message': message,
      'available': available,
      'agentUuid': agentUuid,
      'profileImageUrl': profileImageUrl,
      'clockedIn': clockedIn,
      'loggedInHrs': loggedInHrs,
      'teamLead': teamLead,
      'type': type,
    };
  }
}
