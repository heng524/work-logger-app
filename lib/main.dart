import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const WorkLoggerApp());
}

class WorkLoggerApp extends StatelessWidget {
  const WorkLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '工作日誌',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const WorkHomePage(),
    );
  }
}

class WorkLog {
  String id;
  String date;
  String content;
  double wage;

  WorkLog({required this.id, required this.date, required this.content, required this.wage});

  Map<String, dynamic> toJson() => {'id': id, 'date': date, 'content': content, 'wage': wage};
  factory WorkLog.fromJson(Map<String, dynamic> json) => WorkLog(
    id: json['id'],
    date: json['date'],
    content: json['content'],
    wage: json['wage'],
  );
}

class WorkHomePage extends StatefulWidget {
  const WorkHomePage({super.key});

  @override
  State<WorkHomePage> createState() => _WorkHomePageState();
}

class _WorkHomePageState extends State<WorkHomePage> {
  List<WorkLog> logs = [];
  final _contentController = TextEditingController();
  final _wageController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String selectedMonth = '';

  @override
  void initState() {
    super.initState();
    selectedMonth = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}";
    loadLogs();
  }

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? logsString = prefs.getString('work_logs');
    if (logsString != null) {
      final List decoded = jsonDecode(logsString);
      setState(() {
        logs = decoded.map((item) => WorkLog.fromJson(item)).toList();
      });
    }
  }

  Future<void> saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(logs.map((e) => e.toJson()).toList());
    await prefs.setString('work_logs', encoded);
  }

  void addLog() {
    if (_contentController.text.isEmpty || _wageController.text.isEmpty) return;
    setState(() {
      logs.add(WorkLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
        content: _contentController.text,
        wage: double.tryParse(_wageController.text) ?? 0,
      ));
      _contentController.clear();
      _wageController.clear();
    });
    saveLogs();
  }

  void deleteLog(String id) {
    setState(() {
      logs.removeWhere((element) => element.id == id);
    });
    saveLogs();
  }

  @override
  Widget build(BuildContext context) {
    final monthlyLogs = logs.where((l) => l.date.startsWith(selectedMonth)).toList();
    double totalWage = monthlyLogs.fold(0, (sum, item) => sum + item.wage);

    return Scaffold(
      appBar: AppBar(title: const Text('💼 工作日誌與月結算')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: '工作內容摘要'),
            ),
            TextField(
              controller: _wageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '當日日薪 ($)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: addLog, child: const Text('新增工作紀錄')),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('結算月份: $selectedMonth', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('總天數: ${monthlyLogs.length} 天 | 總薪資: \$${totalWage.toStringAsFixed(0)}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: monthlyLogs.length,
                itemBuilder: (context, index) {
                  final log = monthlyLogs[index];
                  return Card(
                    child: ListTile(
                      title: Text(log.content),
                      subtitle: Text('日期: ${log.date}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('\$${log.wage}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteLog(log.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
