import 'dart:async';

import 'package:flutter/foundation.dart';

class Debounce {
  final Function() work;
  Timer _debounceTimer;
  Duration duration;

  Debounce({
    @required this.duration,
    @required this.work,
  });

   static Future<void> run(Duration duration,Function() work) {
    return Debounce(
      work: work,
      duration: duration,
    ).execute();
  }

  Future<void> execute() {
    Completer completer = Completer<void>();
    if (_debounceTimer?.isActive ?? false) _debounceTimer.cancel();
    _debounceTimer = Timer(duration, () async {
      await work();
      completer.complete();
    });
    return completer.future;
  }
}
