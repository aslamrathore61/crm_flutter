// gps_state.dart
abstract class GPSState {}

class GPSInitial extends GPSState {}

class GPSStatusUpdated extends GPSState {
  final bool isGPSEnabled;
  final bool isPermissionGranted;
  GPSStatusUpdated(this.isGPSEnabled, this.isPermissionGranted);
}
