// enum DownloadTaskType {
//   Photo,
//   Audio,
//   Video,
// }

class DownloadTaskType {
  final String _value;

  const DownloadTaskType(String value) : _value = value;

  String get value{
    return _value;
  }

  get hashCode{
    return _valueToInt;
  }

  int get _valueToInt{
    switch (_value) {
      case 'image': return 0;
      case 'video': return 1;
      case 'audio': return 2;
      default: return null;
    }
  }

  operator ==(e) => e._value == this._value;

  toString() => 'DownloadTaskStatus($_value)';

  // static DownloadTaskStatus from(String value) => DownloadTaskStatus(value);

  static const image = const DownloadTaskType('image');
  static const video = const DownloadTaskType('video');
  static const audio = const DownloadTaskType('audio');
}