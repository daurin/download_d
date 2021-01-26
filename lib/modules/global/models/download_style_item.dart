class DownloadStyleItem {
  final String _value;

  const DownloadStyleItem(String value) : _value = value;

  String get value{
    return _value;
  }

  get hashCode{
    return _valueToInt;
  }

  int get _valueToInt{
    switch (_value) {
      case 'download_style_linear': return 0;
      case 'download_style_circular': return 1;
      default: return null;
    }
  }

  operator ==(e) => e._value == this._value;

  toString() => 'DownloadTaskStatus($_value)';

  static DownloadStyleItem from(String value) => DownloadStyleItem(value);

  static const linear = const DownloadStyleItem('download_style_linear');
  static const circular = const DownloadStyleItem('download_style_circular');
}