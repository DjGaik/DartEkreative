import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';
import 'dart:convert' as convert;
import 'dart:io';

void main(List<String> arguments) async {
  createTable();
  final personName = 'alex';
  final db = sqlite3.open('database.db');
  final info = await getInfo(personName);
  if (info != null) {
    final dbNames = DBNames(info['count'], info['gender'], info['name'], info['probability']);
    insertData(db, dbNames);
  }

  printDBData(db);
  saveDBToTxt();
  db.dispose();
}

Future<Map<String, dynamic>?> getInfo(String personName) async {
  final url = Uri.https('api.genderize.io', '/', {'name': personName});
  final response = await http.get(url);
  print('--------------------------------------------------------------------');
  print(response.body);
  print('--------------------------------------------------------------------');
  if (response.statusCode == 200) {
    return convert.jsonDecode(response.body);
  } else {
    print('Request failed with status code: ${response.statusCode}');
    return null;
  }
}

class DBNames {
  final int count;
  final String gender;
  final String name;
  final double probability;
  DBNames(this.count, this.gender, this.name, this.probability);
  DBNames.fromJson(Map<String, dynamic> json)
      : count = json['count'],
        gender = json['gender'],
        name = json['name'],
        probability = json['probability'];
}

void createTable() {
  final db = sqlite3.open('database.db');
  db.execute('''
    CREATE TABLE IF NOT EXISTS Names (
      count INTEGER,
      gender TEXT,
      name TEXT PRIMARY KEY ON CONFLICT REPLACE,
      probability REAL
    );
  ''');
  db.dispose();
}

void insertData(Database db, DBNames dbNames) {
  final stmt = db.prepare('INSERT INTO Names (count, gender, name, probability) VALUES (?, ?, ?, ?)');
  stmt.execute([dbNames.count, dbNames.gender, dbNames.name, dbNames.probability]);
  stmt.dispose();
}

void printDBData(db) {
  final stmt = db.prepare('SELECT * FROM Names');
  final result = stmt.select();
  for (final row in result) {
    final count = row['count'];
    final gender = row['gender'];
    final name = row['name'];
    final probability = row['probability'];
    print('$count, $name, $gender, $probability');
  }
  print('--------------------------------------------------------------------');
}

void saveDBToTxt() {
  final db = sqlite3.open('database.db');
  final stmt = db.prepare('SELECT * FROM Names');
  final result = stmt.select();
  final file = File('Names.txt');
  final sink = file.openWrite();

  for (final row in result) {
    sink.writeln('${row['count']},${row['gender']},${row['name']},${row['probability']}');
  }

  sink.close();
  stmt.dispose();
  db.dispose();
}
