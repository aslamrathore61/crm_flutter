import 'package:crm_flutter/model/AppConfig.dart';
import 'package:flutter/cupertino.dart';

import '../model/native_item.dart';

@immutable
abstract class NativeItemState {}

class NativeItemInitial extends NativeItemState {}

class NativeItemLoaded extends NativeItemState {
  final NativeItem nativeItem;

  NativeItemLoaded(this.nativeItem);
}

class NativeItemError extends NativeItemState {
  final String message;

  NativeItemError(this.message);
}


/// this call for first time state for check app version and menu verserion

class AppConfigItemLoaded extends NativeItemState {
  final AppConfig appConfig;

  AppConfigItemLoaded(this.appConfig);
}

class AppConfigItemError extends NativeItemState {
  final String message;

  AppConfigItemError(this.message);
}


