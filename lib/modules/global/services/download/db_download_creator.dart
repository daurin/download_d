import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

class DBDownloadCreator {
  Database db;

  Future<Database> init(String dbName) async {
    String path = join(await getDatabasesPath(), '$dbName.db');

    db = await openDatabase(
      path,
      version: 2,
      onOpen: _onOpen,
      onCreate: _onCreate,
      onUpgrade: _onUprade,
    );

    if (db != null) {
      return db;
    }
    return null;
  }

  Future<void> dispose() async {
    await db.close();
  }

  void _onOpen(Database db) {}

  void _onCreate(Database db, int version) async {
    print('database created');

    List<String> scripts = _dbScrip.split(";");
    for (String v in scripts) {
      if (v.trim().isNotEmpty) {
        print(v);
        await db.execute(v.trim());
      }
    }
    // rootBundle.loadString('lib/db/db_script.sql').then((String script) {
    // }).catchError((err) {
    //   print("Error: " + err.toString());
    //   //throw(err);
    // });
  }

  void _onUprade(Database db, int oldVersion, int newVersion) {}

  Future<void> initData() async {
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

  static String _dbScrip = """
  CREATE TABLE IF NOT EXISTS "DOWNLOAD_TASK"(
    "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "id_custom" TEXT NOT NULL UNIQUE,
    "url" TEXT NOT NULL,
    "status" INTEGER NOT NULL,
    "progress" INTEGER NOT NULL,
    "headers" TEXT NOT NULL,
    "save_dir" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "size" INTEGER NOT NULL,
    "resumable" NUMERIC NULL,
    "display_name" TEXT NOT NULL,
    "show_notification" NUMERIC NOT NULL,
    "mime_type" TEXT NOT NULL,
    "index" INTEGER NULL,
    "created_at" NUMERIC NOT NULL,
    "completed_at" NUMERIC NULL,
    "limit_bandwidth" INTEGER NULL,
    "duration" INTEGER NULL,
    "thumbnail_url" TEXT NULL,
    "metadata" TEXT NULL
);
""";
}