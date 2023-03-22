import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

const medicationTableName = "medications";

void main() {
  runApp(const MedicationManagerApp());
}

class MedicationManagerApp extends StatelessWidget {
  const MedicationManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Manager',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const MedicationListPage(),
    );
  }
}

class Medication {
  late int id;
  late String title;
  late int productionDate;
  late int expirationDate;
  late int activeSubstanceId;
  late String barcodeNumbers;

  Medication({
    required this.id,
    required this.title,
    required this.productionDate,
    required this.expirationDate,
    required this.activeSubstanceId,
    required this.barcodeNumbers,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          productionDate == other.productionDate &&
          expirationDate == other.expirationDate &&
          activeSubstanceId == other.activeSubstanceId &&
          barcodeNumbers == other.barcodeNumbers);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      productionDate.hashCode ^
      expirationDate.hashCode ^
      activeSubstanceId.hashCode ^
      barcodeNumbers.hashCode;

  @override
  String toString() {
    return 'Medication{ id: $id, title: $title, productionDate: $productionDate, expirationDate: $expirationDate, activeSubstanceId: $activeSubstanceId, barcodeNumbers: $barcodeNumbers,}';
  }

  Medication copyWith({
    int? id,
    String? title,
    int? productionDate,
    int? expirationDate,
    int? activeSubstanceId,
    String? barcodeNumbers,
  }) {
    return Medication(
      id: id ?? this.id,
      title: title ?? this.title,
      productionDate: productionDate ?? this.productionDate,
      expirationDate: expirationDate ?? this.expirationDate,
      activeSubstanceId: activeSubstanceId ?? this.activeSubstanceId,
      barcodeNumbers: barcodeNumbers ?? this.barcodeNumbers,
    );
  }

  Map<String, dynamic> toMap({bool withId = false}) {
    final clazz = {
      'title': title,
      'productionDate': productionDate,
      'expirationDate': expirationDate,
      'activeSubstanceId': activeSubstanceId,
      'barcodeNumbers': barcodeNumbers,
    };

    if (withId) {
      clazz['id'] = id;
    }

    return clazz;
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int,
      title: map['title'] as String,
      productionDate: map['productionDate'] as int,
      expirationDate: map['expirationDate'] as int,
      activeSubstanceId: map['activeSubstanceId'] as int,
      barcodeNumbers: map['barcodeNumbers'] as String,
    );
  }

  factory Medication.create(
      {required String title,
      required int productionDate,
      required int expirationDate,
      required int activeSubstanceId}) {
    return Medication(
        id: -1,
        title: title,
        productionDate: productionDate,
        expirationDate: expirationDate,
        activeSubstanceId: activeSubstanceId,
        barcodeNumbers: "");
  }
}

class MedicationListPage extends StatefulWidget {
  const MedicationListPage({super.key});

  @override
  MedicationListPageState createState() => MedicationListPageState();
}

class MedicationListPageState extends State<MedicationListPage> {
  late Database _database;
  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasePath = await getApplicationDocumentsDirectory();
    final path = join(databasePath.path, 'data.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) {
        db.execute(
          'CREATE TABLE $medicationTableName(id INTEGER PRIMARY KEY, title TEXT, productionDate INTEGER, expirationDate INTEGER, activeSubstanceId INTEGER, barcodeNumbers TEXT)',
        );

        _fillWithFakeData();
      },
    );
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final dbMedications = await _database.query(medicationTableName);

    List<Medication> medications =
        dbMedications.map((element) => Medication.fromMap(element)).toList();

    setState(() {
      _medications = medications;
    });
  }

  Future<void> _fillWithFakeData() async {
    final List<Medication> medications = [];
  }

  Future<void> _addMedication(Medication medication) async {
    await _database.insert(medicationTableName, medication.toMap());
    _loadMedications();
  }

  Future<void> _deleteMedication(int id) async {
    await _database
        .delete(medicationTableName, where: 'id = ?', whereArgs: [id]);
    _loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Manager'),
      ),
      body: ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final medication = _medications[index];
          final formattedDate = medication.productionDate.toSimpleDate();

          return ListTile(
            leading: Text('#${medication.id}'),
            title: Text(medication.title),
            subtitle: Text('Production date: $formattedDate'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () =>
                  _showDeleteSnackbar(context, medication.title, medication.id),
            ),
            onLongPress: () => {
              ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                  content: const Text('Material Banner'),
                  actions: [
                    TextButton(
                        onPressed: () => {
                              ScaffoldMessenger.of(context)
                                  .clearMaterialBanners()
                            },
                        child: const Text('Dismiss')),
                  ]))
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showDeleteSnackbar(
      BuildContext context, String title, int id) async {
    const duration = Duration(seconds: 3);

    bool isUndone = false;

    final deletedMedicationIndex =
        _medications.indexWhere((element) => element.id == id);

    if (deletedMedicationIndex == -1) {
      return;
    }

    final deletedMedication = _medications[deletedMedicationIndex];

    _medications.removeAt(deletedMedicationIndex);
    setState(() {
      _medications = _medications.toList();
    });

    Timer(
        duration,
        () => {
              if (!isUndone) {_deleteMedication(id)}
            });

    final snackbar = SnackBar(
      content: Text('Medication "$title" deleted'),
      action: SnackBarAction(
          label: 'Undo',
          onPressed: () => {
                isUndone = true,
                _medications.insert(deletedMedicationIndex, deletedMedication),
                setState(() {
                  _medications = _medications.toList();
                })
              }),
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  Future<void> _showAddMedicationDialog(BuildContext context,
      {String? inputText, int? productionDate, int? expirationDate}) async {
    TextEditingController inputController = TextEditingController();
    inputController.text = inputText ?? '';

    int? pickedProductionDate = productionDate;
    int? pickedExpirationDate = expirationDate;

    Column verticalColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          autofocus: true,
          controller: inputController,
          decoration: const InputDecoration(hintText: 'Medication title'),
        ),
        const SizedBox(height: 20),
        Text(
            'Production date: ${pickedProductionDate?.toSimpleDate() ?? 'Not picked yet'}'),
        MaterialButton(
            child: const Text('Pick production date'),
            onPressed: () => {
                  showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                          lastDate: DateTime.now(),
                          helpText: 'Pick production date')
                      .then((value) => {
                            pickedProductionDate =
                                value?.millisecondsSinceEpoch ??
                                    pickedProductionDate,
                            Navigator.pop(context),
                            _showAddMedicationDialog(context,
                                inputText: inputController.text,
                                productionDate: pickedProductionDate,
                                expirationDate: pickedExpirationDate)
                          })
                }),
        Text(
            'Expiration date: ${pickedExpirationDate?.toSimpleDate() ?? 'Not picked yet'}'),
        MaterialButton(
            child: const Text('Pick expiration date'),
            onPressed: () => {
                  showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2500),
                          helpText: 'Pick expiration date')
                      .then((value) => {
                            pickedExpirationDate =
                                value?.millisecondsSinceEpoch ??
                                    pickedExpirationDate,
                            Navigator.pop(context),
                            _showAddMedicationDialog(context,
                                inputText: inputController.text,
                                productionDate: pickedProductionDate,
                                expirationDate: pickedExpirationDate)
                          })
                }),
      ],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Medication'),
          content: verticalColumn,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                final finalTitle = inputController.text.trim();
                if (finalTitle.isEmpty) {
                  _showSnackbarError(context, 'Title is empty');
                  return;
                }

                final finalProductionDate = pickedProductionDate ?? -1;
                if (finalProductionDate == -1) {
                  _showSnackbarError(context, 'Production date is not picked');
                  return;
                }
                final finalExpirationDate = pickedExpirationDate ?? -1;
                if (finalExpirationDate == -1) {
                  _showSnackbarError(context, 'Expiration date is not picked');
                  return;
                }

                final newMedication = Medication.create(
                    title: finalTitle,
                    productionDate: finalProductionDate,
                    expirationDate: finalExpirationDate,
                    activeSubstanceId: 0);

                _addMedication(newMedication);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSnackbarError(
      BuildContext context, String errorText) async {
    final snackbar = SnackBar(
      content: Text('Error: $errorText'),
      duration: const Duration(milliseconds: 1500),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
}

extension SimpleDateFormatter on int {
  String toSimpleDate() {
    try {
      return DateFormat('dd.MM.yyyy')
          .format(DateTime.fromMillisecondsSinceEpoch(this));
    } catch (e) {
      return '';
    }
  }
}
