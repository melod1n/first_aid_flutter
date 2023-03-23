import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_date/random_date.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import 'package:get/get.dart';

import 'app_theme.dart';

const medicationTableName = "medications";
const sqlCreateTable =
    'CREATE TABLE $medicationTableName(id INTEGER PRIMARY KEY, title TEXT, productionDate INTEGER, expirationDate INTEGER, activeSubstanceId INTEGER, barcodeNumbers TEXT)';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MedicationManagerApp(savedThemeMode: savedThemeMode));
}

class MedicationManagerApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const MedicationManagerApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: Themes.light,
        dark: Themes.dark,
        initial: savedThemeMode ?? AdaptiveThemeMode.system,
        builder: (theme, darkTheme) => MaterialApp(
              title: 'Medication Manager',
              theme: theme,
              darkTheme: darkTheme,
              home: const MedicationListPage(),
            ));
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
      {int id = -1,
      required String title,
      required int productionDate,
      required int expirationDate,
      required int activeSubstanceId,
      String barcodeNumbers = ''}) {
    return Medication(
        id: id,
        title: title,
        productionDate: productionDate,
        expirationDate: expirationDate,
        activeSubstanceId: activeSubstanceId,
        barcodeNumbers: barcodeNumbers);
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
  final List<int> _selectedMedicationsIds = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> menuItems = _selectedMedicationsIds.isEmpty
        ? []
        : [
            MenuItemButton(
                child: Icon(Icons.delete_rounded,
                    color: context.theme.colorScheme.onPrimary),
                onPressed: () {
                  if (_selectedMedicationsIds.length == 1) {
                    final selectedMedicationIndex = _medications.indexWhere(
                        (element) =>
                            element.id == _selectedMedicationsIds.first);
                    final selectedMedication =
                        _medications[selectedMedicationIndex];

                    _showDeleteSnackbar(context, selectedMedication.id,
                        selectedMedication.title);
                  } else {
                    _showDeleteAlert(context, _selectedMedicationsIds);
                  }
                })
          ];

    final popupMenuButton = PopupMenuButton(itemBuilder: (context) {
      return [
        PopupMenuItem(
            onTap: () {
              AdaptiveTheme.of(context).toggleThemeMode();
            },
            child: const Text('Toggle theme'))
      ];
    });

    final List<Widget> actions = [];
    actions.addAll(menuItems);
    actions.add(popupMenuButton);

    final scaffold = Scaffold(
      backgroundColor: context.theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
            'Medication Manager ${_selectedMedicationsIds.isNotEmpty ? '(${_selectedMedicationsIds.length})' : ''}'),
        actions: actions,
      ),
      body: ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final medication = _medications[index];
          final formattedDate = medication.productionDate.toSimpleDate();

          return Container(
            color: (_selectedMedicationsIds.contains(medication.id)
                ? context.theme.colorScheme.primary.withOpacity(0.5)
                : Colors.transparent),
            child: ListTile(
              leading: Text('#${medication.id}'),
              title: Text(medication.title),
              subtitle: Text('Production date: $formattedDate'),
              onTap: () {
                if (_selectedMedicationsIds.isNotEmpty) {
                  // selection mode
                  setState(() {
                    if (_selectedMedicationsIds.contains(medication.id)) {
                      _selectedMedicationsIds
                          .removeWhere((element) => element == medication.id);
                    } else {
                      _selectedMedicationsIds.add(medication.id);
                    }
                  });
                } else {
                  // open info mode
                  _showAddMedicationDialog(context,
                      id: medication.id,
                      inputText: medication.title,
                      productionDate: medication.productionDate,
                      expirationDate: medication.expirationDate);
                }
              },
              onLongPress: () {
                if (_selectedMedicationsIds.isNotEmpty) {
                  // selection mode
                  setState(() {
                    if (_selectedMedicationsIds.contains(medication.id)) {
                      _selectedMedicationsIds
                          .removeWhere((element) => element == medication.id);
                    } else {
                      _selectedMedicationsIds.add(medication.id);
                    }
                  });
                } else {
                  // enter selection mode
                  setState(() {
                    _selectedMedicationsIds.add(medication.id);
                  });
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicationDialog(context),
        child: const Icon(Icons.add),
      ),
    );

    return scaffold;
  }

  Future<void> _initDatabase() async {
    final databasePath = await getApplicationDocumentsDirectory();
    final path = join(databasePath.path, 'data.db');

    var fillFakeData = false;

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) {
        fillFakeData = true;
        db.execute(sqlCreateTable);
      },
    );

    if (fillFakeData) {
      await _fillWithFakeData();
    }
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
    final currentYear = DateTime.now().year;
    final productionDateRandomizer = RandomDate.withRange(1990, currentYear);
    final expirationDateRandomizer =
        RandomDate.withRange(currentYear, currentYear * 2);

    final List<Medication> medications = List.generate(
        30,
        (index) => Medication(
            id: index,
            title: 'Test medication #${index + 1}',
            productionDate:
                productionDateRandomizer.random().millisecondsSinceEpoch,
            expirationDate:
                expirationDateRandomizer.random().millisecondsSinceEpoch,
            activeSubstanceId: index,
            barcodeNumbers: ''));

    _addMedications(medications, withRefresh: false);
  }

  Future<void> _addMedication(Medication medication,
      {bool withRefresh = true}) async {
    await _database.insert(
        medicationTableName, medication.toMap(withId: medication.id != -1),
        conflictAlgorithm: ConflictAlgorithm.replace);

    if (withRefresh) {
      _loadMedications();
    }
  }

  Future<void> _addMedications(List<Medication> medications,
      {bool withRefresh = true}) async {
    final batch = _database.batch();
    for (var medication in medications) {
      batch.insert(medicationTableName, medication.toMap());
    }

    await batch.commit(noResult: true);

    if (withRefresh) {
      _loadMedications();
    }
  }

  Future<void> _deleteMedication(int id, {bool withRefresh = true}) async {
    await _database
        .delete(medicationTableName, where: 'id = ?', whereArgs: [id]);

    if (withRefresh) {
      _loadMedications();
    }
  }

  Future<void> _deleteMedications(List<int> ids,
      {bool withRefresh = true}) async {
    final batch = _database.batch();
    for (var id in ids) {
      batch.delete(medicationTableName, where: 'id = ?', whereArgs: [id]);
    }

    await batch.commit(noResult: true);

    if (withRefresh) {
      _loadMedications();
    }
  }

  Future<void> _showDeleteAlert(BuildContext context, List<int> ids) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content:
              const Text('Are you sure you want to delete this medications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                await _deleteMedications(ids);

                setState(() {
                  _selectedMedicationsIds.clear();
                });
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteSnackbar(
      BuildContext context, int id, String title) async {
    const duration = Duration(seconds: 3);

    bool isUndone = false;

    final deletedMedicationIndex =
        _medications.indexWhere((element) => element.id == id);

    if (deletedMedicationIndex == -1) {
      return;
    }

    final deletedMedication = _medications[deletedMedicationIndex];

    setState(() {
      _selectedMedicationsIds.clear();
      _medications.removeAt(deletedMedicationIndex);
    });

    Timer(duration, () {
      if (!isUndone) {
        _deleteMedication(id);
      }
    });

    final snackbar = SnackBar(
      content: Text('Medication "$title" deleted'),
      action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            isUndone = true;

            setState(() {
              _selectedMedicationsIds.add(deletedMedication.id);
              _medications.insert(deletedMedicationIndex, deletedMedication);
            });
          }),
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  Future<void> _showAddMedicationDialog(BuildContext context,
      {int? id,
      String? inputText,
      int? productionDate,
      int? expirationDate}) async {
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
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                foregroundColor: context.theme.colorScheme.onSecondary,
                backgroundColor: context.theme.colorScheme.secondary),
            child: const Text('Pick production date'),
            onPressed: () => {
                  showDatePicker(
                          context: context,
                          initialDate: productionDate == null
                              ? DateTime.now()
                              : DateTime.fromMillisecondsSinceEpoch(
                                  productionDate),
                          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                          lastDate: DateTime.now(),
                          helpText: 'Pick production date')
                      .then((value) => {
                            pickedProductionDate =
                                value?.millisecondsSinceEpoch ??
                                    pickedProductionDate,
                            Navigator.pop(context),
                            _showAddMedicationDialog(context,
                                id: id,
                                inputText: inputController.text,
                                productionDate: pickedProductionDate,
                                expirationDate: pickedExpirationDate)
                          })
                }),
        const SizedBox(height: 10),
        Text(
            'Expiration date: ${pickedExpirationDate?.toSimpleDate() ?? 'Not picked yet'}'),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                foregroundColor: context.theme.colorScheme.onSecondary,
                backgroundColor: context.theme.colorScheme.secondary),
            child: const Text('Pick expiration date'),
            onPressed: () => {
                  showDatePicker(
                          context: context,
                          initialDate: expirationDate == null
                              ? DateTime.now()
                              : DateTime.fromMillisecondsSinceEpoch(
                                  expirationDate),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2500),
                          helpText: 'Pick expiration date')
                      .then((value) => {
                            pickedExpirationDate =
                                value?.millisecondsSinceEpoch ??
                                    pickedExpirationDate,
                            Navigator.pop(context),
                            _showAddMedicationDialog(context,
                                id: id,
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
          title: Text(id == null ? 'Add Medication' : 'Edit Medication'),
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
                    id: id ?? -1,
                    title: finalTitle,
                    productionDate: finalProductionDate,
                    expirationDate: finalExpirationDate,
                    activeSubstanceId: 0);

                _addMedication(newMedication);
              },
              child: Text(id == null ? 'Add' : 'Edit'),
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
