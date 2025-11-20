import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../custom_widgets/variables.dart';
import 'notification_model.dart';

class NotificationDatabase {
  static final NotificationDatabase instance = NotificationDatabase._init();

  static Database? _database;

  NotificationDatabase._init();

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDB('${Variables.notifTable}.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 4, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    //const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NULL';
    const integerType = 'INTEGER NULL';

    await db.execute('''
      CREATE TABLE ${Variables.notifTable} (  
        ${NotificationDataFields.reservedId} $integerType, 
        ${NotificationDataFields.userId} $integerType, 
        ${NotificationDataFields.mTicketId} $integerType, 
        ${NotificationDataFields.mreservedId} $integerType,  
        ${NotificationDataFields.notifDate} $textType,  
        ${NotificationDataFields.dtIn} $textType
        )
      ''');
  }

  Future<void> insertUpdate(dynamic json) async {
    final db = await instance.database;

    const columns =
        '${NotificationDataFields.reservedId},'
        '${NotificationDataFields.userId},'
        '${NotificationDataFields.mTicketId},'
        '${NotificationDataFields.mreservedId},'
        '${NotificationDataFields.notifDate},'
        '${NotificationDataFields.dtIn}';
    final insertValues =
        "${json[NotificationDataFields.reservedId]},"
        "${json[NotificationDataFields.userId]},"
        "${json[NotificationDataFields.mTicketId]},"
        "${json[NotificationDataFields.mreservedId]},"
        "'${json[NotificationDataFields.notifDate]}',"
        "'${json[NotificationDataFields.dtIn]}'";

    final existingData = await NotificationDatabase.instance
        .readNotificationById(json[NotificationDataFields.reservedId]);

    if (existingData != null) {
      await db!.transaction((txn) async {
        var batch = txn.batch();

        batch.rawUpdate(
          '''
          UPDATE ${Variables.notifTable}
          SET ${NotificationDataFields.reservedId} = ?, 
              ${NotificationDataFields.userId} = ?, 
                ${NotificationDataFields.mTicketId} = ?, 
                  ${NotificationDataFields.mreservedId} = ?,  
              ${NotificationDataFields.notifDate} = ? , 
             
              ${NotificationDataFields.dtIn} = ? 
          WHERE ${NotificationDataFields.reservedId} = ?
          ''',
          [
            json[NotificationDataFields.reservedId],
            json[NotificationDataFields.userId],
            json[NotificationDataFields.mTicketId],
            json[NotificationDataFields.mreservedId],
            json[NotificationDataFields.notifDate],
            json[NotificationDataFields.dtIn],
            json[NotificationDataFields.reservedId],
          ],
        );

        await batch.commit(noResult: true);
      });
    } else {
      await db!.transaction((txn) async {
        var batch = txn.batch();

        batch.rawInsert(
          'INSERT INTO ${Variables.notifTable} ($columns) VALUES ($insertValues)',
        );

        await batch.commit(noResult: true);
      });
    }
  }

  Future<dynamic> readNotificationById(int id) async {
    final db = await instance.database;

    final maps = await db!.query(
      Variables.notifTable,
      columns: NotificationDataFields.values,
      where: '${NotificationDataFields.reservedId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<dynamic> readNotificationByResId(int reserveId) async {
    final db = await instance.database;

    final maps = await db!.query(
      Variables.notifTable,
      columns: NotificationDataFields.values,
      where: '${NotificationDataFields.reservedId} = ?',
      whereArgs: [reserveId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<List<dynamic>> readAllNotifications() async {
    final db = await instance.database;

    final result = await db!.query(
      Variables.notifTable,
      orderBy: "${NotificationDataFields.reservedId} ASC",
    );

    return result;
  }

  Future deleteAll() async {
    final db = await instance.database;

    db!.delete(Variables.notifTable);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;

    return await db!.delete(
      Variables.notifTable,
      where: 'reserved_id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;

    db!.close();
  }
}
