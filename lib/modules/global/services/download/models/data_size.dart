import 'dart:math';

test(){
  Duration(
    
  );
}

class DataSize{
  int _bytes;

  DataSize({
    int bytes=0,
    int kilobytes=0,
  }){
    _bytes=0;
    if(bytes>0){
      _bytes+=bytes;
    }
    if(kilobytes>0){
      _bytes+=kilobytes*1000;
    }
  }

  static DataSize zero = DataSize(bytes: 0);

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

  String format({
    int decimals = 1,
    String suffix,
    bool showSuffix=true,
  }){
    if (_bytes <= 0) return "0 B";
    int i;
    if(suffix!=null){
      i=_suffixes.indexOf(suffix);
    }
    if(i==null)i = (log(_bytes) / log(1024)).floor();
    String formatted=((_bytes / pow(1024, i)).toStringAsFixed(decimals));
    if(showSuffix)formatted+=' ' + _suffixes[i];
    return formatted;
  }

  String getSuffix(int bytes){
    int i = (log(bytes) / log(1024)).floor();
    return _suffixes[i];
  }

  int get inBytes =>_bytes;
  int get inKilobytes => _bytes~/1000;

}
