import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

abstract class DB {
  static Database db;

  static Future<void> init() async {
    String path = join(await getDatabasesPath(), 'download_d.db');

    print(path);

    if (db != null) {
      return;
    }

    db = await openDatabase(path,version: 2, onOpen: _onOpen, onCreate: _onCreate, onUpgrade: _onUprade);
  }

  static Future<void> dispose()async{
    await db.close();
  }

  static void _onOpen(Database db) {

  }

  static void _onCreate(Database db, int version) {
    print('database created');

    rootBundle.loadString('lib/db/db_script.sql')
      .then((String script) {
        List<String> scripts = script.split(";");
        scripts.forEach((v) {
          if (v.isNotEmpty) {
            print(v);
            db.execute(v.trim());
          }
        });
      })
      .catchError((err) {
        print("Error: " + err.toString());
        //throw(err);
      });
  }

  static void _onUprade(Database db, int oldVersion, int newVersion) {

  }


  static Future<void> initData()async{
    // int idUser=await User.add(User());
    // int idAccount=await Account.add(Account(name: 'Efectivo',idUser: idUser,orderCustom: 0));

    // for (int i = 0; i < 632; i++) {
    //   await Transaction.add(Transaction(
    //     idUser: idUser,
    //     amount: 1000,
    //     description: 'Transaction ${i+1}',
    //     account: Account(
    //       id: idAccount,
    //     ),
    //     date: DateTime.now(),
    //     transactionType: TransactionType.Income,
    //     repeatMode: TransactionRepeatMode.EveryDay,
    //   ));
    // }
    
  }

  // static String _getStringFromBytes(ByteData data) {
  //   final buffer = data.buffer;
  //   var list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  //   return utf8.decode(list);
  // }
}