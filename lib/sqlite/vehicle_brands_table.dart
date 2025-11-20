// ignore_for_file: depend_on_referenced_packages

import 'package:luvpay/custom_widgets/variables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'vehicle_brands_model.dart';

class VehicleBrandsTable {
  static final VehicleBrandsTable instance = VehicleBrandsTable._init();

  static Database? _database;

  VehicleBrandsTable._init();

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDB('${Variables.vhBrands}.db');
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
      CREATE TABLE ${Variables.vhBrands} (  
        ${VHBrandsDataFields.vhTypeId} $integerType, 
        ${VHBrandsDataFields.vhBrandId} $integerType,  
        ${VHBrandsDataFields.vhBrandName} $textType,
         ${VHBrandsDataFields.image} $textType
        )
      ''');
  }

  Future<void> insertUpdate(dynamic json) async {
    final db = await instance.database;

    const columns =
        '${VHBrandsDataFields.vhBrandId},'
        '${VHBrandsDataFields.vhTypeId},'
        '${VHBrandsDataFields.vhBrandName},'
        '${VHBrandsDataFields.image}';
    final insertValues =
        "${json[VHBrandsDataFields.vhBrandId]},"
        "${json[VHBrandsDataFields.vhTypeId]},"
        "'${json[VHBrandsDataFields.vhBrandName]}',"
        "'${json[VHBrandsDataFields.image]}'";

    await db!.transaction((txn) async {
      var batch = txn.batch();

      batch.rawInsert(
        'INSERT INTO ${Variables.vhBrands} ($columns) VALUES ($insertValues)',
      );

      await batch.commit(noResult: true);
    });
  }

  Future<dynamic> readVehicleBrandsById(int id) async {
    final db = await instance.database;

    final maps = await db!.query(
      Variables.vhBrands,
      columns: VHBrandsDataFields.values,
      where: '${VHBrandsDataFields.vhBrandId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<String?> readVehicleBrandsByVbId(int vtId, int vbId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      Variables.vhBrands,
      orderBy: "${VHBrandsDataFields.vhBrandId} ASC",
    );

    final Map<String, dynamic> matchingRecord = maps.firstWhere(
      (record) =>
          record[VHBrandsDataFields.vhTypeId] == vtId &&
          record[VHBrandsDataFields.vhBrandId] == vbId,
      orElse:
          () =>
              {}, // Provide a default value or handle the case where no matching element is found
    );

    String? brandName;
    brandName = matchingRecord[VHBrandsDataFields.vhBrandName] as String?;

    return brandName;
  }

  Future<String?> getBrandImage(int vtId, int vbId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      Variables.vhBrands,
      orderBy: "${VHBrandsDataFields.vhBrandId} ASC",
    );

    final Map<String, dynamic> matchingRecord = maps.firstWhere(
      (record) =>
          record[VHBrandsDataFields.vhTypeId] == vtId &&
          record[VHBrandsDataFields.vhBrandId] == vbId,
      orElse:
          () =>
              {}, // Provide a default value or handle the case where no matching element is found
    );

    String? image;
    image = matchingRecord[VHBrandsDataFields.image] as String?;

    return image;
  }

  Future<dynamic> readVBrandDataByVTID(int vtId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      Variables.vhBrands,
      orderBy: "${VHBrandsDataFields.vhTypeId} ASC",
    );
    final Map<String, dynamic> matchingRecord = maps.firstWhere(
      (record) => record[VHBrandsDataFields.vhTypeId] == vtId,
    );

    return matchingRecord;
  }

  Future<List<dynamic>> readAllVHBrands() async {
    final db = await instance.database;

    final result = await db!.query(
      Variables.vhBrands,
      orderBy: "${VHBrandsDataFields.vhTypeId} ASC",
    );

    return result;
  }

  Future deleteAll() async {
    final db = await instance.database;

    db!.delete(Variables.vhBrands);
  }

  Future<int> deleteMessageById(int id) async {
    final db = await database;

    return await db!.delete(
      Variables.vhBrands,
      where: 'push_msg_id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;

    db!.close();
  }
}
