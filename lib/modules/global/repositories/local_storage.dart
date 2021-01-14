import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  Box _localStorageBox;

  factory LocalStorage() {
    return _instance;
  }

  LocalStorage._internal();

  Future<void> init() async {
    if (!kIsWeb) {
      Directory directory = await getApplicationDocumentsDirectory();
      _localStorageBox = await Hive.openBox('data', path: directory.path);
    } else {
      _localStorageBox = await Hive.openBox('data');
    }
  }

  void dispose() {
    Hive.close();
  }

  Future<void> setItem(String key, dynamic value)async{
    await _localStorageBox.put(key, value);
  }

  dynamic getItem(String key, {dynamic defaultValue}) {
    return _localStorageBox.get(
      key,
      defaultValue: defaultValue,
    );
  }
  
}
