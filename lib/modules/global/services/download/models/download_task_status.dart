class DownloadTaskStatus {
  final String _value;

  const DownloadTaskStatus(String value) : _value = value;

  String get value{
    return _value;
  }

  get hashCode{
    return _valueToInt;
  }

  int get _valueToInt{
    switch (_value) {
      case 'undefined': return 0;
      case 'enqueued': return 1;
      case 'running': return 2;
      case 'complete': return 3;
      case 'failed': return 4;
      case 'canceled': return 5;
      case 'paused': return 6;
      case 'failed_conexion': return 7;
      default: return null;
    }
  }

  operator ==(e) => e._value == this._value;

  toString() => 'DownloadTaskStatus($_value)';

  // static DownloadTaskStatus from(String value) => DownloadTaskStatus(value);

  static const undefined = const DownloadTaskStatus('undefined');
  static const enqueued = const DownloadTaskStatus('enqueued');
  static const running = const DownloadTaskStatus('running');
  static const complete = const DownloadTaskStatus('complete');
  static const failed = const DownloadTaskStatus('failed');
  static const failedConexion = const DownloadTaskStatus('failed_conexion');
  static const canceled = const DownloadTaskStatus('canceled');
  static const paused = const DownloadTaskStatus('paused');
}