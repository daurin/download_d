import 'dart:math';

abstract class DataSize{
  static const _suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];

  static String formatBytes(
    int bytes, {
    int decimals = 1,
    String suffix,
    bool showSuffix=true,
  }) {
    if (bytes <= 0) return "0 B";
    int i;
    if(suffix!=null){
      i=_suffixes.indexOf(suffix);
    }
    if(i==null)i = (log(bytes) / log(1024)).floor();
    String formatted=((bytes / pow(1024, i)).toStringAsFixed(decimals));
    if(showSuffix)formatted+=' ' + _suffixes[i];
    return formatted;
  }

  static String getSuffix(int bytes){
    int i = (log(bytes) / log(1024)).floor();
    return _suffixes[i];
  }
}

