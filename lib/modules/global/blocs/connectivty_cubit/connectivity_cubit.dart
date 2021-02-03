import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_cubit_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityCubitState> {
  ConnectivityCubit() : super(ConnectivityCubitState.initialState);

  StreamSubscription<ConnectivityResult> _connectivityChangedSubscription;

  Future<void> listenStatusConnection() async {
    _connectivityChangedSubscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    ConnectivityResult connectivity = await Connectivity().checkConnectivity();
    emit(state.copyWith(
      connectivity: connectivity,
    ));
  }

  void removeListener() {
    _connectivityChangedSubscription?.cancel();
  }

  void _onConnectivityChanged(ConnectivityResult connectivity) {
    emit(state.copyWith(
      connectivity: connectivity,
    ));
  }
}
