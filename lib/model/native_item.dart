import 'package:hive/hive.dart';

part 'native_item.g.dart';


@HiveType(typeId: 0)
class NativeItem {
  @HiveField(0)
  List<Bottom>? bottom;
  @HiveField(1)
  List<Side>? side;
  @HiveField(2)
  List<Profile>? profile;

  NativeItem({
    this.bottom,
    this.side,
    this.profile,
  });

  factory NativeItem.fromJson(Map<String, dynamic> json) {
    if (json['Bottom'] != null) {
      var bottomList = json['Bottom'] as List;
      List<Bottom> bottomItems =
      bottomList.map((i) => Bottom.fromJson(i)).toList();
      return NativeItem(bottom: bottomItems);
    }
    if (json['Side'] != null) {
      var sideList = json['Side'] as List;
      List<Side> sideItems = sideList.map((i) => Side.fromJson(i)).toList();
      return NativeItem(side: sideItems);
    }
    if (json['Profile'] != null) {
      var sideList = json['Profile'] as List;
      List<Profile> profileItems = sideList.map((i) => Profile.fromJson(i)).toList();
      return NativeItem(profile: profileItems);
    }
    return NativeItem(bottom: [], side: [], profile: []);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.bottom != null) {
      data['Bottom'] = bottom?.map((v) => v.toJson()).toList();
    }
    if (this.side != null) {
      data['Side'] = side?.map((v) => v.toJson()).toList();
    }
    if (this.profile != null) {
      data['Profile'] = profile?.map((v) => v.toJson()).toList();
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
  @HiveField(4)
  String? naivgate;

  Bottom({this.title, this.icon, this.uRL, this.id, this.naivgate});

  factory Bottom.fromJson(Map<String, dynamic> json) {
    return Bottom(
      title: json['title'],
      icon: json['icon'],
      uRL: json['URL'],
      id: json['id'],
      naivgate: json['naivgate'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['icon'] = this.icon;
    data['URL'] = this.uRL;
    data['id'] = this.id;
    data['naivgate'] = this.naivgate;
    return data;
  }
}

@HiveType(typeId: 2)
class Side {
  @HiveField(0)
  String? title;
  @HiveField(1)
  String? icon;
  @HiveField(2)
  String? uRL;
  @HiveField(3)
  String? id;
  @HiveField(4)
  String? menuIcon;
  @HiveField(5)
  List<SubItem>? subList;
  @HiveField(6)
  String? naivgate;

  Side({this.title, this.icon, this.uRL, this.id, this.menuIcon, this.subList, this.naivgate});

  factory Side.fromJson(Map<String, dynamic> json) {
    if (json['Sub'] != null) {
      var subList = json['Sub'] as List;
      List<SubItem> subItems = subList.map((i) => SubItem.fromJson(i)).toList();
      return Side(
        title: json['title'],
        icon: json['icon'],
        uRL: json['URL'],
        id: json['id'],
        menuIcon: json['menuIcon'],
        subList: subItems,
        naivgate: json['naivgate'],

      );
    }
    return Side(
      title: json['title'],
      icon: json['icon'],
      uRL: json['URL'],
      id: json['id'],
      menuIcon: json['menuIcon'],
      subList: [],
      naivgate: json['naivgate'],

    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['icon'] = this.icon;
    data['URL'] = this.uRL;
    data['id'] = this.id;
    data['menuIcon'] = this.menuIcon;
    data['naivgate'] = this.naivgate;
    if (this.subList != null) {
      data['Sub'] = subList?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@HiveType(typeId: 3)
class SubItem {
  @HiveField(0)
  String? title;
  @HiveField(1)
  String? icon;
  @HiveField(2)
  String? uRL;
  @HiveField(3)
  String? id;
  @HiveField(4)
  String? menuIcon;

  SubItem({this.title, this.icon, this.uRL, this.id, this.menuIcon});

  factory SubItem.fromJson(Map<String, dynamic> json) {
    return SubItem(
      title: json['title'],
      icon: json['icon'],
      uRL: json['URL'],
      id: json['id'],
      menuIcon: json['menuIcon'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['icon'] = this.icon;
    data['URL'] = this.uRL;
    data['id'] = this.id;
    data['menuIcon'] = this.menuIcon;
    return data;
  }
}



@HiveType(typeId: 4)
class Profile {
  @HiveField(0)
  String? title;
  @HiveField(1)
  String? icon;
  @HiveField(2)
  String? uRL;
  @HiveField(3)
  String? id;

  Profile({this.title, this.icon, this.uRL, this.id});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
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