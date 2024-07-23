// gps_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'gps_event.dart';
import 'gps_state.dart';

class GPSBloc extends Bloc<GPSEvent, GPSState> {
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  Timer? _permissionCheckTimer;

  GPSBloc() : super(GPSInitial()) {
    on<CheckGPS>(_onCheckGPS);
    on<UpdateGPSStatus>(_onUpdateGPSStatus);

    _startServiceStatusStream();
    _startPermissionCheckTimer();
  }

  void _startServiceStatusStream() {
    _serviceStatusStreamSubscription = Geolocator.getServiceStatusStream().listen((ServiceStatus status) async {
      bool isPermissionGranted = await _checkLocationPermission();
      add(UpdateGPSStatus(status == ServiceStatus.enabled, isPermissionGranted));
    });
  }

  void _startPermissionCheckTimer() {
    _permissionCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      bool isGPSEnabled = await Geolocator.isLocationServiceEnabled();
      bool isPermissionGranted = await _checkLocationPermission();
      print('isPermissionGranted $isPermissionGranted');
      print('isGPSEnabled $isGPSEnabled');
      add(UpdateGPSStatus(isGPSEnabled, isPermissionGranted));
    });
  }

  Future<void> _onCheckGPS(CheckGPS event, Emitter<GPSState> emit) async {
    bool isGPSEnabled = await Geolocator.isLocationServiceEnabled();
    bool isPermissionGranted = await _checkLocationPermission();
    emit(GPSStatusUpdated(isGPSEnabled, isPermissionGranted));
  }

  void _onUpdateGPSStatus(UpdateGPSStatus event, Emitter<GPSState> emit) {
    emit(GPSStatusUpdated(event.isGPSEnabled, event.isPermissionGranted));
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  Future<void> close() {
    _serviceStatusStreamSubscription?.cancel();
    _permissionCheckTimer?.cancel();
    return super.close();
  }
}
