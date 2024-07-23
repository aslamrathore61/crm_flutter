// gps_event.dart
abstract class GPSEvent {}

class CheckGPS extends GPSEvent {}

class UpdateGPSStatus extends GPSEvent {
  final bool isGPSEnabled;
  final bool isPermissionGranted;
  UpdateGPSStatus(this.isGPSEnabled, this.isPermissionGranted);
}
