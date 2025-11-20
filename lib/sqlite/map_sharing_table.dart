// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../custom_widgets/variables.dart';
import 'sharing_data_model.dart';

class MapSharingTable {
  static final MapSharingTable instance = MapSharingTable._init();

  static Database? _database;

  MapSharingTable._init();

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDB('${Variables.locSharing}.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NULL';
    const integerType = 'INTEGER NULL';
    const blobType = 'BLOB NULL';
    const doubleType = 'REAL NULL';

    await db.execute('''
      CREATE TABLE ${Variables.locSharing} (  
        ${MapSharingDataFields.geoconId} $integerType, 
        ${MapSharingDataFields.userId} $integerType,  
        ${MapSharingDataFields.geoShareId} $integerType,  
        ${MapSharingDataFields.latitude} $doubleType,  
        ${MapSharingDataFields.longitude} $doubleType,  
        ${MapSharingDataFields.createdDate} $textType,  
        ${MapSharingDataFields.userName} $textType,  
        ${MapSharingDataFields.image} $blobType
        )
      ''');
  }

  Future<void> insertUpdate(dynamic jsonData) async {
    final db = await instance.database;
    final encodedData = compressAndEncode(jsonData[MapSharingDataFields.image]);
    final Map<String, dynamic> values = {
      MapSharingDataFields.geoconId: jsonData[MapSharingDataFields.geoconId],
      MapSharingDataFields.userId: jsonData[MapSharingDataFields.userId],
      MapSharingDataFields.geoShareId:
          jsonData[MapSharingDataFields.geoShareId],
      MapSharingDataFields.latitude: jsonData[MapSharingDataFields.latitude],
      MapSharingDataFields.longitude: jsonData[MapSharingDataFields.longitude],
      MapSharingDataFields.createdDate:
          jsonData[MapSharingDataFields.createdDate],
      MapSharingDataFields.userName: jsonData[MapSharingDataFields.userName],
      MapSharingDataFields.image: encodedData,
    };
    await db!.transaction((txn) async {
      var batch = txn.batch();
      // Retrieve stored data from SQLite

      //if data is exist.
      final count = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM ${Variables.locSharing} WHERE ${MapSharingDataFields.geoconId} = ?',
          [values[MapSharingDataFields.geoconId]],
        ),
      );

      if (count == 0) {
        batch.insert(Variables.locSharing, values);
      } else {
        batch.update(
          Variables.locSharing,
          values,
          where: '${MapSharingDataFields.geoconId} = ?',
          whereArgs: [values[MapSharingDataFields.geoconId]],
        );
      }

      await batch.commit(noResult: true);
    });
  }

  List<int> compressAndEncode(String data) {
    final compressedData = utf8.encode(data);
    final encodedData = zlib.encode(compressedData);
    return encodedData;
  }

  // Function to decode and decompress data
  String decodeAndDecompress(Uint8List encodedData) {
    final decompressedData = zlib.decode(encodedData);
    return utf8.decode(decompressedData);
  }

  Future<List<dynamic>> readAllMapShareData() async {
    final db = await instance.database;
    final result = await db!.query(
      Variables.locSharing,
      orderBy: "${MapSharingDataFields.geoconId} ASC",
    );

    return result;
  }

  Future deleteAll() async {
    final db = await instance.database;

    db!.delete(Variables.locSharing);
  }

  Future<int> deleteDataById(int id) async {
    final db = await database;

    return await db!.delete(
      Variables.locSharing,
      where: 'geo_connect_id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;

    db!.close();
  }
}
