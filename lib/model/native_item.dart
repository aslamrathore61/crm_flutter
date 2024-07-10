import 'package:hive/hive.dart';

part 'native_item.g.dart'; // Generated file by running flutter pub run build_runner build

@HiveType(typeId: 0)
class NativeItem {
  @HiveField(0)
  List<Bottom>? bottom;

  NativeItem({this.bottom});

  factory NativeItem.fromJson(Map<String, dynamic> json) {
    if (json['Bottom'] != null) {
      var bottomList = json['Bottom'] as List;
      List<Bottom> bottomItems = bottomList.map((i) => Bottom.fromJson(i)).toList();
      return NativeItem(bottom: bottomItems);
    }
    return NativeItem(bottom: []);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.bottom != null) {
      data['Bottom'] = bottom?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@HiveType(typeId: 1)
class Bottom {
  @HiveField(0)
  String? title;
  @HiveField(1)
  String? icon;
  @HiveField(2)
  String? uRL;
  @HiveField(3)
  String? id;

  Bottom({this.title, this.icon, this.uRL, this.id});

  factory Bottom.fromJson(Map<String, dynamic> json) {
    return Bottom(
      title: json['title'],
      icon: json['icon'],
      uRL: json['URL'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['icon'] = this.icon;
    data['URL'] = this.uRL;
    data['id'] = this.id;
    return data;
  }
}
