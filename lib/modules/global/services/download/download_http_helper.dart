import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'models/data_size.dart';

class DownloadHttpHelper {
  static Future<HttpClientResponse> head({
    @required String url,
    Map<String, dynamic> headers,
  }) async {
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.headUrl(Uri.parse(url));
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }
    HttpClientResponse response = await request.close();
    return response;
  }

  static Future<CancelableOperation<void>> download({
    @required String url,
    @required String savePath,
    bool resume = true,
    DataSize limitBandwidth,
    Map<String, dynamic> headers,
    void Function(DataSize receivedLength, DataSize contentLength) onReceived,
    void Function(Object err) onError,
    void Function(DataSize byteInSeconds) onSpeedDownloadChange,
    void Function(int) onProgress,
    void Function() onComplete,
    Duration onReceibedDelayCall = const Duration(milliseconds: 200),
  }) async {
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request;
    HttpClientResponse response;
    CancelableCompleter cancelableCompleter;
    IOSink ioSink;
    int downloadedBytes = 0;
    Timer timerOneSecond;

    try {
      File file = File(savePath);
      request = await httpClient.getUrl(Uri.parse(url));

      bool fileExist = await file.exists();

      if (fileExist && resume) {
        downloadedBytes = await file.length();
      } else if (fileExist) {
        await file.delete();
        file=await file.create();
      } else {
        file=await file.create();
      }
      if (downloadedBytes > 0) {
        request.headers
            .add('Range', 'bytes=' + downloadedBytes.toString() + '-');
      }

      ioSink = file.openWrite(
        mode: FileMode.append,
      );

      int received = downloadedBytes;
      int receivedInOneSeconds = 0;
      int lastProgress;
      int lastReceived;
      int contentLength = 0;
      bool requestIsPaused = false;

      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.add(key, value);
        });
      }

      StreamSubscription<List<int>> responseSubscription;
      int lastOnReceibedCalled = DateTime.now().millisecondsSinceEpoch;
      int lastProgressCalled = DateTime.now().millisecondsSinceEpoch;

      cancelableCompleter = CancelableCompleter<void>(
        onCancel: () async {
          await responseSubscription?.cancel();
          responseSubscription = null;
          requestIsPaused=true;
          timerOneSecond?.cancel();
          await response?.detachSocket();
          request?.abort();
        },
      );

      void Function(List<int>) onListen = (List<int> bytes) async {
        if (requestIsPaused) return;
        ioSink.add(bytes);
        received += bytes.length;
        receivedInOneSeconds += bytes.length;

        if (limitBandwidth != null) {
          if (receivedInOneSeconds >= limitBandwidth.inBytes &&
              !requestIsPaused) {
            print('pause');
            requestIsPaused = true;
            // throw Exception('cancel')
            // responseSubscription.pause()
            await responseSubscription?.cancel();
            await response.detachSocket();
            responseSubscription = null;
            request?.abort();
          }
        }

        if (onReceived != null) {
          if (lastReceived != received) {
            if ((DateTime.now().millisecondsSinceEpoch - lastOnReceibedCalled) >
                onReceibedDelayCall.inMilliseconds) {
              lastOnReceibedCalled = DateTime.now().millisecondsSinceEpoch;
              onReceived(
                  DataSize(bytes: received), DataSize(bytes: contentLength));
              lastReceived = received;
            }
          }
        }
        if (onProgress != null) {
          if (lastReceived != received) {
            if ((DateTime.now().millisecondsSinceEpoch - lastProgressCalled) >
                onReceibedDelayCall.inMilliseconds) {
              int progress = (received * 100) ~/ contentLength;
              if (lastProgress != progress) {
                lastProgressCalled = DateTime.now().millisecondsSinceEpoch;
                onProgress(progress);
                lastProgress = progress;
              }
            }
          }
        }
      };
      void Function() onDone = () {
        ioSink?.close();
        timerOneSecond?.cancel();
        httpClient.close();
        responseSubscription?.cancel();
        if(onReceived!=null)onReceived(DataSize(bytes: received), DataSize(bytes: contentLength));
        if (onComplete != null) onComplete();
      };

      Function onErrorListen = (err) {
        if (onError != null) onError(err);
        responseSubscription?.cancel();
        timerOneSecond.cancel();
        ioSink?.close();
        httpClient.close();
      };

      response = await request.close();
      contentLength = response.headers.contentLength;
      contentLength += downloadedBytes;

      responseSubscription = response.listen(
        onListen,
        onDone: onDone,
        onError: onErrorListen,
        cancelOnError: true,
      );

      timerOneSecond = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (onSpeedDownloadChange != null) {
          onSpeedDownloadChange(DataSize(bytes: receivedInOneSeconds));
        }
        receivedInOneSeconds = 0;
        if (limitBandwidth != null) {
          if (requestIsPaused) {
            print('resume');
            requestIsPaused = false;
            // responseSubscription.resume();
            // downloadedBytes = 0;
            // downloadedBytes = await file.length();
            // received = downloadedBytes??0;
            request=null;
            request = await httpClient.getUrl(Uri.parse(url));
              request.headers
                  .add('Range', 'bytes=' + received.toString() + '-');
            if (headers != null) {
              headers.forEach((key, value) {
                request.headers.add(key, value);
              });
            }

            response = await request.close();
             contentLength = response.headers.contentLength;
             contentLength += downloadedBytes;
            responseSubscription = response.listen(
              onListen,
              onDone: onDone,
              onError: onErrorListen,
              cancelOnError: true,
            );
          }
        }
      });
    } catch (err) {
      if (onError != null) onError(err);
      timerOneSecond?.cancel();
      httpClient.close();
      ioSink?.close();
      print(err);
    }

    return cancelableCompleter?.operation;
  }
}