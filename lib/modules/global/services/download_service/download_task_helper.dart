import 'dart:io';
import 'package:flutter/foundation.dart';
import 'data_size.dart';

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

  static Future<void> download(
      {@required String url,
      @required String savePath,
      Map<String, dynamic> headers}) async {
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));

    int _received = 0;

    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }
    HttpClientResponse response = await request.close();
    response.listen((event) {
      _received += event.length;
      print(DataSize.formatBytes(_received));
      // print(event);
    });

    httpClient.close();
  }
}
