import 'dart:math';
import 'package:filesize/filesize.dart';

test() {
  Duration();
}

class DataSize {
  int _bytes;

  static const int _kilobyteInByte=1024;
  static const int _kibibyteInByte=1000;

  static const int _megabyteInByte=1000000;
  static const int _mebibyteInByte=1049000;

  static const int _gigabyteInByte=1000000000;
  static const int _gibibyteInByte=1074000000;

  static const int _terabyteInByte=1000000000000;
  static const int _tebibyteInByte=1100000000000;

  DataSize({
    int bytes = 0,
    int kilobytes = 0,
    int kibibytes = 0,
    int megabytes = 0,
    int mebibytes = 0,
    int gigabytes = 0,
    int gibibytes = 0,
    int terabytes = 0,
    int tebibytes = 0,
  }) {
    _bytes = 0;
    print(_bytes);
    if (bytes > 0) {
      _bytes += bytes;
    }
    if (kilobytes > 0) {
      _bytes += kilobytes * _kilobyteInByte;
    }
    if(kibibytes > 0){
      _bytes += kibibytes * _kibibyteInByte;
    }
    if (megabytes > 0) {
      _bytes += megabytes * _megabyteInByte;
    }
    if(mebibytes > 0){
      _bytes += mebibytes * _mebibyteInByte;
    }
    if (gigabytes > 0) {
      _bytes += gigabytes * _gigabyteInByte;
    }
    if (gibibytes > 0) {
      _bytes += gibibytes * _gibibyteInByte;
    }
    if(terabytes > 0){
      _bytes += terabytes * _terabyteInByte;
    }
    if(tebibytes > 0){
      _bytes += tebibytes * _tebibyteInByte;
    }
  }

  static DataSize zero = DataSize(bytes: 0);

  static const _suffixes = [
    "B",
    "KB",
    "MB",
    "GB",
    "TB",
    "PB",
    "EB",
    "ZB",
    "YB"
  ];

  static String _formatBytes(
    int bytes, {
    int decimals = 3,
    String suffix,
    bool showSuffix = true,
  }) {
    if (bytes <= 0) return "0 B";
    int i;
    if (suffix != null) {
      i = _suffixes.indexOf(suffix);
    }
    if (i == null) i = (log(bytes) / log(1024)).floor();
    String formatted = ((bytes / pow(1024, i)).toStringAsFixed(decimals));
    if (showSuffix) formatted += ' ' + _suffixes[i];
    return formatted;
  }

  String format({
    int decimals = 2,
    String suffix,
    bool showSuffix = true,
    bool binaryFormat=true
  }) {
    // return filesize(_bytes,decimals);
    int binaryValue=1024;
    if(!binaryFormat)binaryValue=1000;

    if (_bytes <= 0) return "0 B";
    int i;
    if (suffix != null) {
      i = _suffixes.indexOf(suffix);
    }
    if (i == null) i = (log(_bytes) / log(binaryValue)).floor();
    String formatted = ((_bytes / pow(binaryValue, i)).toStringAsFixed(decimals));
    if (showSuffix) formatted += ' ' + _suffixes[i];
    return formatted;
  }

  String getSuffix(int bytes) {
    int i = (log(bytes) / log(1024)).floor();
    return _suffixes[i];
  }

  int get inBytes => _bytes;
  
  int get inKilobytes => _bytes ~/ _kilobyteInByte;
  int get inKibibytes => _bytes ~/ _kibibyteInByte;

  int get inMegabytes => _bytes ~/ _megabyteInByte;
  int get inMebibytes => _bytes ~/ _mebibyteInByte;

  int get inGigabytes => _bytes ~/ _gigabyteInByte;
  int get inGibibytes => _bytes ~/ _gibibyteInByte;

  int get inTerabytes => _bytes ~/ _terabyteInByte;
  int get inTibibytes => _bytes ~/ _tebibyteInByte;
  
}
