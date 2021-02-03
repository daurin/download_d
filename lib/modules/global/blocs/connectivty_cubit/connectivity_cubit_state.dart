import 'package:connectivity/connectivity.dart';
import 'package:download_d/modules/global/blocs/connectivty_cubit/connectivity_cubit.dart';

class ConnectivityCubitState {
  final ConnectivityResult connectivity;

  ConnectivityCubitState({this.connectivity});

  ConnectivityCubitState copyWith({
    ConnectivityResult connectivity,
  }) {
    return ConnectivityCubitState(
      connectivity: connectivity ?? this.connectivity,
    );
  }

  static ConnectivityCubitState get initialState {
    return ConnectivityCubitState(
      connectivity: ConnectivityResult.none,
    );
  }

  bool get hasConnection {
    return connectivity == ConnectivityResult.mobile ||
        connectivity == ConnectivityResult.wifi;
  }
}
