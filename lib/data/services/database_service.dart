import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite database: opening, schema creation and migrations.
///
/// The default constructor uses the platform sqflite factory. Tests inject
/// `sqflite_common_ffi`'s factory and an in-memory path.
class DatabaseService {
  DatabaseService({DatabaseFactory? factory, String? path})
      : _factory = factory,
        _path = path;

  static const _dbFileName = 'track_team.db';
  static const _schemaVersion = 1;

  final DatabaseFactory? _factory;
  final String? _path;
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final path = _path ?? p.join(await factory.getDatabasesPath(), _dbFileName);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
      ),
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE device_traces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        imei TEXT,
        trace_date INTEGER NOT NULL DEFAULT 0,
        last_synced_at INTEGER,
        team_name TEXT,
        user_name TEXT,
        user_type TEXT,
        country TEXT,
        state TEXT,
        lga TEXT,
        ward TEXT,
        health_facility TEXT,
        distribution_point TEXT,
        settlement TEXT,
        latitude REAL,
        longitude REAL,
        device_model TEXT,
        app_version TEXT,
        status TEXT NOT NULL DEFAULT 'OFFLINE',
        UNIQUE(device_id, trace_date) ON CONFLICT REPLACE
      )
    ''');
    await db.execute('CREATE INDEX idx_traces_geo ON device_traces('
        'lga, ward, health_facility, distribution_point)');
    await db.execute('CREATE INDEX idx_traces_status ON device_traces(status)');
    await db.execute('CREATE INDEX idx_traces_device ON device_traces('
        'device_id, trace_date DESC)');
    await db.execute('''
      CREATE TABLE import_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT NOT NULL,
        imported_at INTEGER NOT NULL,
        row_count INTEGER NOT NULL,
        skipped_count INTEGER NOT NULL,
        team_count INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
