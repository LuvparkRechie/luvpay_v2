// ignore_for_file: depend_on_referenced_packages

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../custom_widgets/variables.dart';
import 'pa_message_model.dart';

class PaMessageDatabase {
  static final PaMessageDatabase instance = PaMessageDatabase._init();

  static Database? _database;

  PaMessageDatabase._init();

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDB('${Variables.paMessageTable}.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NULL';
    const integerType = 'INTEGER NULL';

    await db.execute('''
      CREATE TABLE ${Variables.paMessageTable} (  
        ${PaMessageDataFields.pushMsgId} $integerType, 
        ${PaMessageDataFields.userId} $integerType, 
        ${PaMessageDataFields.message} $textType,
        ${PaMessageDataFields.createdDate} $textType, 
        ${PaMessageDataFields.status} $textType, 
         ${PaMessageDataFields.isRead} $textType, 
        ${PaMessageDataFields.runOn} $textType
        )
      ''');
  }

  Future<void> insertUpdate(dynamic json) async {
    final db = await instance.database;

    const columns =
        '${PaMessageDataFields.pushMsgId},'
        '${PaMessageDataFields.userId},'
        '${PaMessageDataFields.message},'
        '${PaMessageDataFields.createdDate},'
        '${PaMessageDataFields.status},'
        '${PaMessageDataFields.isRead},'
        '${PaMessageDataFields.runOn}';
    final insertValues =
        "${json[PaMessageDataFields.pushMsgId]},"
        "${json[PaMessageDataFields.userId]},"
        "'${json[PaMessageDataFields.message].toString().replaceAll("'", "''")}',"
        "'${json[PaMessageDataFields.createdDate]}',"
        "'${json[PaMessageDataFields.status]}',"
        "'${json[PaMessageDataFields.isRead]}',"
        "'${json[PaMessageDataFields.runOn]}'";

    final existingData = await PaMessageDatabase.instance.readNotificationById(
      json[PaMessageDataFields.pushMsgId],
    );

    if (existingData != null) {
      await db!.transaction((txn) async {
        var batch = txn.batch();

        batch.rawUpdate(
          '''
          UPDATE ${Variables.paMessageTable}
          SET ${PaMessageDataFields.pushMsgId} = ?, 
              ${PaMessageDataFields.userId} = ?, 
              ${PaMessageDataFields.message} = ?, 
              ${PaMessageDataFields.createdDate} = ? , 
               ${PaMessageDataFields.status} = ? , 
                  ${PaMessageDataFields.isRead} = ? ,  
              ${PaMessageDataFields.runOn} = ? 
          WHERE ${PaMessageDataFields.pushMsgId} = ?
          ''',
          [
            json[PaMessageDataFields.pushMsgId],
            json[PaMessageDataFields.userId],
            json[PaMessageDataFields.message],
            json[PaMessageDataFields.createdDate],
            json[PaMessageDataFields.status],
            json[PaMessageDataFields.isRead],
            json[PaMessageDataFields.runOn],
            json[PaMessageDataFields.pushMsgId],
          ],
        );

        await batch.commit(noResult: true);
      });
    } else {
      await db!.transaction((txn) async {
        var batch = txn.batch();

        batch.rawInsert(
          'INSERT INTO ${Variables.paMessageTable} ($columns) VALUES ($insertValues)',
        );

        await batch.commit(noResult: true);
      });
    }
  }

  Future<dynamic> readNotificationById(int id) async {
    final db = await instance.database;

    final maps = await db!.query(
      Variables.paMessageTable,
      columns: PaMessageDataFields.values,
      where: '${PaMessageDataFields.pushMsgId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<dynamic> readNotificationByMateId(
    int mateId,
    String createdDate,
  ) async {
    final db = await instance.database;

    final maps = await db!.query(
      Variables.paMessageTable, // Change this line
      columns: PaMessageDataFields.values,
      where:
          '${PaMessageDataFields.pushMsgId} = ? AND ${PaMessageDataFields.runOn} = ?',
      whereArgs: [mateId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<List<dynamic>> getUnreadMessages() async {
    final db = await instance.database;

    final maps = await db!.query(
      Variables.paMessageTable,
      columns: PaMessageDataFields.values,
      where: '${PaMessageDataFields.isRead} = ?',
      whereArgs: ['N'],
    );

    return maps;
  }

  Future<List<dynamic>> readAllMessage() async {
    final db = await instance.database;

    final result = await db!.query(
      Variables.paMessageTable,
      orderBy: "${PaMessageDataFields.pushMsgId} ASC",
    );

    return result;
  }

  Future deleteAll() async {
    final db = await instance.database;

    db!.delete(Variables.paMessageTable);
  }

  Future<int> deleteMessageById(int id) async {
    final db = await database;

    return await db!.delete(
      Variables.paMessageTable,
      where: 'push_msg_id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;

    db!.close();
  }
}
