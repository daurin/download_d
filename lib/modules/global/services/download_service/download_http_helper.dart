import 'dart:async';
import 'dart:io';
import 'package:download_d/modules/global/services/download_service/data_size.dart';
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
    int limitBandwidth,
    Map<String, dynamic> headers,
    void Function(int receivedLength, int contentLength) onReceived,
    void Function(int byteInSeconds) onSpeedDownloadChange,
    void Function(int) onProgress,
    void Function() onComplete,
  }) async {
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request;
    IOSink ioSink;
    int downloadedBytes = 0;

    try {
      File file = File(savePath);
      request = await httpClient.getUrl(Uri.parse(url));

      if (await file.exists() && resume) {
        downloadedBytes = await file.length();
      } else {
        await file.create();
      }
      if (downloadedBytes > 0)
        request.headers
            .add('Range', 'bytes=' + downloadedBytes.toString() + '-');

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

      Timer timer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (onSpeedDownloadChange != null) {
          onSpeedDownloadChange(receivedInOneSeconds);
        }
        // request = await httpClient.getUrl(Uri.parse(url));

        // await request.close();
        if (limitBandwidth != null) {
          if (requestIsPaused) {
            await download(
              url: url,
              savePath: savePath,
              limitBandwidth: limitBandwidth,
              headers: headers,
              onReceived: onReceived,
              onSpeedDownloadChange: onSpeedDownloadChange,
              onProgress: onProgress,
              onComplete: onComplete,
              resume: resume,
            );
          }
        }

        receivedInOneSeconds = 0;
      });
      int lastCallOnOneSeconds = DateTime.now().millisecondsSinceEpoch;

      responseSubscription = response.listen(
        (bytes) async {
          print(DataSize.formatBytes(bytes.length));
          received += bytes.length;
          receivedInOneSeconds += bytes.length;

          // ioSink.add(bytes);

          if (limitBandwidth != null) {
            if (receivedInOneSeconds > limitBandwidth) {
              // httpClient.close(force: true);
              // throw Exception('cancel')
              // responseSubscription.pause();
              response.detachSocket();
              httpClient.close(force: true);
              requestIsPaused = true;
            }
          }

          if (onReceived != null) {
            if (lastReceived != received) {
              onReceived(received, contentLength);
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
        },
        onDone: () {
          ioSink?.close();
          timer.cancel();
          responseSubscription?.cancel();
          if (onComplete != null) onComplete();
        },
        onError: () {
          responseSubscription?.cancel();
          timer.cancel();
          ioSink?.close();
        },
        cancelOnError: true,
      );
    } catch (err) {
      ioSink?.close();
      print(err);
    }
    return request;
  }
}
