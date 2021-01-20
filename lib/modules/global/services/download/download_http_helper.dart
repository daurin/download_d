import 'dart:async';
import 'dart:io';
import 'package:download_d/modules/global/services/download/data_size.dart';
import 'package:flutter/foundation.dart';

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

  static Future<HttpClientRequest> download({
    @required String url,
    @required String savePath,
    bool resume = true,
    DataSize limitBandwidth,
    Map<String, dynamic> headers,
    void Function(DataSize receivedLength, DataSize contentLength) onReceived,
    void Function(DataSize byteInSeconds) onSpeedDownloadChange,
    void Function(int) onProgress,
    void Function() onComplete,
    Duration onReceibedDelayCall = const Duration(milliseconds: 200),
  }) async {
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request;
    IOSink ioSink;
    int downloadedBytes = 0;

    Timer timerOneSecond;

    try {
      File file = File(savePath);
      request = await httpClient.getUrl(Uri.parse(url));

      if (await file.exists() && resume) {
        downloadedBytes = await file.length();
      } else {
        await file.create();
      }
      if (downloadedBytes > 0) {
        request.headers
            .add('Range', 'bytes=' + downloadedBytes.toString() + '-');
      }

      ioSink = file.openWrite(
        mode: FileMode.writeOnlyAppend,
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
      HttpClientResponse response = await request.close();
      contentLength = response.headers.contentLength;
      contentLength += downloadedBytes;

      StreamSubscription<List<int>> responseSubscription;
      int lastCallOnReceibed = DateTime.now().millisecondsSinceEpoch;

      void Function(List<int>) onListen = (List<int> bytes) async {
        received += bytes.length;
        receivedInOneSeconds += bytes.length;

        ioSink.add(bytes);

        if (limitBandwidth != null) {
          if (receivedInOneSeconds >= limitBandwidth.inBytes && !requestIsPaused) {
            // throw Exception('cancel')
            // responseSubscription.pause();
            response.detachSocket();
            request.abort();
            requestIsPaused = true;
          }
        }

        if (onReceived != null) {
          if (lastReceived != received) {
            if ((DateTime.now().millisecondsSinceEpoch - lastCallOnReceibed) >
                onReceibedDelayCall.inMilliseconds)
              onReceived(
                  DataSize(bytes: received), DataSize(bytes: contentLength));
            lastReceived = received;
          }
        }
        if (onProgress != null) {
          int progress = (received * 100) ~/ contentLength;
          if (lastProgress != progress) {
            onProgress(progress);
            lastProgress = progress;
          }
        }
      };
      void Function() onDone = () {
        onReceived(DataSize(bytes: received), DataSize(bytes: contentLength));
        ioSink?.close();
        timerOneSecond.cancel();
        httpClient.close();
        responseSubscription?.cancel();
        if (onComplete != null) onComplete();
      };

      void Function() onError = () {
        responseSubscription?.cancel();
        timerOneSecond.cancel();
        ioSink?.close();
        httpClient.close();
      };

      responseSubscription = response.listen(
        onListen,
        onDone: onDone,
        onError: onError,
        cancelOnError: true,
      );

      timerOneSecond = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (onSpeedDownloadChange != null) {
          onSpeedDownloadChange(DataSize(bytes: receivedInOneSeconds));
        }
        receivedInOneSeconds = 0;
        if (limitBandwidth != null) {
          if (requestIsPaused) {
            requestIsPaused = false;

            responseSubscription?.cancel();
            responseSubscription = null;
            downloadedBytes = await file.length();
            received = downloadedBytes;
            request = await httpClient.getUrl(Uri.parse(url));
            request.headers
                .add('Range', 'bytes=' + downloadedBytes.toString() + '-');
            if (headers != null) {
              headers.forEach((key, value) {
                request.headers.add(key, value);
              });
            }

            response = await request.close();
            // contentLength = response.headers.contentLength;
            // contentLength += downloadedBytes;
            responseSubscription = response.listen(
              onListen,
              onDone: onDone,
              onError: onError,
              cancelOnError: true,
            );
          }
        }
      });
    } catch (err) {
      httpClient.close();
      ioSink?.close();
      timerOneSecond?.cancel();
      print(err);
    }
    return request;
  }
}
