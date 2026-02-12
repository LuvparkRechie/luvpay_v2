// // ignore_for_file: depend_on_referenced_packages

// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';

// import '../../../shared/widgets/variables.dart';
// import 'share_location_model.dart';

// class ShareLocationDatabase {
//   static final ShareLocationDatabase instance = ShareLocationDatabase._init();

//   static Database? _database;

//   ShareLocationDatabase._init();

//   Future<Database?> get database async {
//     if (_database != null) return _database;

//     _database = await _initDB('${Variables.shareLocTable}.db');
//     return _database;
//   }

//   Future<Database> _initDB(String filePath) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, filePath);

//     return await openDatabase(path, version: 1, onCreate: _createDB);
//   }

//   Future _createDB(Database db, int version) async {
//     const textType = 'TEXT NULL';
//     const integerType = 'INTEGER NULL';
//     await db.execute('''
//       CREATE TABLE ${Variables.shareLocTable} (  
//         ${ShareLocationDataFields.connectMateId} $integerType,
//           ${ShareLocationDataFields.updatedDate} $textType
//         )
//       ''');
//   }

//   Future<void> insertUpdate(dynamic json) async {
//     final db = await instance.database;

//     const columns =
//         '${ShareLocationDataFields.connectMateId},'
//         '${ShareLocationDataFields.updatedDate}';
//     final insertValues =
//         "${json[ShareLocationDataFields.connectMateId]},"
//         "'${json[ShareLocationDataFields.updatedDate]}'";

//     final existingData = await ShareLocationDatabase.instance
//         .readNotificationById(json[ShareLocationDataFields.connectMateId]);

//     if (existingData != null) {
//       await db!.transaction((txn) async {
//         var batch = txn.batch();

//         batch.rawUpdate(
//           '''
//           UPDATE ${Variables.shareLocTable}
//           SET ${ShareLocationDataFields.connectMateId} = ?,  
//               ${ShareLocationDataFields.updatedDate} = ? 
//           WHERE ${ShareLocationDataFields.connectMateId} = ?
//           ''',
//           [
//             json[ShareLocationDataFields.connectMateId],
//             json[ShareLocationDataFields.updatedDate],
//             json[ShareLocationDataFields.connectMateId],
//           ],
//         );

//         await batch.commit(noResult: true);
//       });
//     } else {
//       await db!.transaction((txn) async {
//         var batch = txn.batch();

//         batch.rawInsert(
//           'INSERT INTO ${Variables.shareLocTable} ($columns) VALUES ($insertValues)',
//         );

//         await batch.commit(noResult: true);
//       });
//     }
//   }

//   Future<dynamic> readNotificationById(int id) async {
//     final db = await instance.database;

//     final maps = await db!.query(
//       Variables.shareLocTable,
//       columns: ShareLocationDataFields.values,
//       where: '${ShareLocationDataFields.connectMateId} = ?',
//       whereArgs: [id],
//     );

//     if (maps.isNotEmpty) {
//       return maps.first;
//     } else {
//       return null;
//     }
//   }

//   Future<dynamic> readNotificationByMateId(
//     int mateId,
//     String updatedDate,
//   ) async {
//     final db = await instance.database;

//     final maps = await db!.query(
//       Variables.shareLocTable, // Change this line
//       columns: ShareLocationDataFields.values,
//       where:
//           '${ShareLocationDataFields.connectMateId} = ? AND ${ShareLocationDataFields.updatedDate} = ?',
//       whereArgs: [mateId, updatedDate],
//     );

//     if (maps.isNotEmpty) {
//       return maps.first;
//     } else {
//       return null;
//     }
//   }

//   Future<List<dynamic>> readAllNotifications() async {
//     final db = await instance.database;

//     final result = await db!.query(
//       Variables.shareLocTable,
//       orderBy: "${ShareLocationDataFields.connectMateId} ASC",
//     );

//     return result;
//   }

//   Future<int> deleteMessageById(int id) async {
//     final db = await database;

//     return await db!.delete(
//       Variables.shareLocTable,
//       where: 'geo_connect_mate_id = ?',
//       whereArgs: [id],
//     );
//   }

//   Future deleteAll() async {
//     final db = await instance.database;

//     db!.delete(Variables.shareLocTable);
//   }

//   Future close() async {
//     final db = await instance.database;

//     db!.close();
//   }
// }
