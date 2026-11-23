import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

final notifications = FlutterLocalNotificationsPlugin();
const categories = ['شخصی', 'تماس', 'بانک', 'پیامک', 'خرید', 'کار', 'سلامتی'];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fa_IR');
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
    const InitializationSettings(android: android),
  );
  runApp(const DayFlowApp());
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    this.note = '',
    this.done = false,
    this.imagePath,
    this.audioPath,
    this.reminder,
  });

  final String id;
  final String title;
  final String category;
  final DateTime date;
  final String note;
  final bool done;
  final String? imagePath;
  final String? audioPath;
  final DateTime? reminder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'category': category,
        'note': note,
        'done': done,
        'imagePath': imagePath,
        'audioPath': audioPath,
        'reminder': reminder?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        category: json['category'] as String,
        note: (json['note'] ?? '') as String,
        done: (json['done'] ?? false) as bool,
        imagePath: json['imagePath'] as String?,
        audioPath: json['audioPath'] as String?,
        reminder: json['reminder'] == null
            ? null
            : DateTime.parse(json['reminder'] as String),
      );

  Task copyWith({bool? done}) => Task(
        id: id,
        title: title,
        date: date,
        category: category,
        note: note,
        done: done ?? this.done,
        imagePath: imagePath,
        audioPath: audioPath,
        reminder: reminder,
      );
}

class DayFlowApp extends StatelessWidget {
  const DayFlowApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DayFlow',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff6658d3),
          ),
          scaffoldBackgroundColor: const Color(0xfff6f5fb),
          fontFamily: 'Roboto',
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Task> tasks = [];
  DateTime selected = DateTime.now();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasks') ?? '[]';
    final decoded = jsonDecode(raw) as List<dynamic>;
    if (!mounted) return;
    setState(() {
      tasks = decoded
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
      loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tasks',
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }

  List<Task> get selectedTasks =>
      tasks.where((task) => isSameDay(task.date, selected)).toList();

  List<Task> get overdueTasks => tasks
      .where(
        (task) =>
            !task.done &&
            task.date.isBefore(DateTime.now()) &&
            !isSameDay(task.date, DateTime.now()),
      )
      .toList();

  Future<void> _addTask() async {
    final task = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskPage()),
    );
    if (task != null) {
      setState(() => tasks.add(task));
      await _save();
    }
  }

  Future<void> _toggleTask(Task task) async {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    setState(() => tasks[index] = task.copyWith(done: !task.done));
    await _save();
  }

  Future<void> _deleteTask(Task task) async {
    setState(() => tasks.removeWhere((item) => item.id == task.id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final completed = selectedTasks.where((task) => task.done).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DayFlow',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _addTask,
            icon: const Icon(Icons.add_circle_outline, size: 28),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('کار جدید'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff6658d3), Color(0xff9287ed)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'برنامه‌ریزی روزانه',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE، d MMMM', 'fa_IR').format(selected),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _metric('${selectedTasks.length}', 'همه کارها'),
                          const SizedBox(width: 24),
                          _metric('$completed', 'انجام‌شده'),
                          const SizedBox(width: 24),
                          _metric(
                            '${selectedTasks.length - completed}',
                            'باقی‌مانده',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar<Task>(
                      locale: 'fa_IR',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2035, 12, 31),
                      focusedDay: selected,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, selected),
                      onDaySelected: (day, focusedDay) =>
                          setState(() => selected = day),
                      eventLoader: (day) => tasks
                          .where((task) => isSameDay(task.date, day))
                          .toList(),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      calendarStyle: const CalendarStyle(
                        markersMaxCount: 3,
                        outsideDaysVisible: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _section(
                  isSameDay(selected, DateTime.now())
                      ? 'کارهای امروز'
                      : 'کارهای این روز',
                  selectedTasks.length,
                ),
                if (selectedTasks.isEmpty) _empty('برای این روز کاری ثبت نشده است'),
                ...selectedTasks.map(_taskCard),
                if (overdueTasks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _section('کارهای به‌تعویق‌افتاده', overdueTasks.length),
                  ...overdueTasks.map((task) => _taskCard(task, late: true)),
                ],
              ],
            ),
    );
  }

  Widget _metric(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  Widget _section(String title, int count) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xffe9e6ff),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff6658d3),
              ),
            ),
          ),
        ],
      );

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Text(message, style: const TextStyle(color: Colors.black45)),
        ),
      );

  Widget _taskCard(Task task, {bool late = false}) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(top: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Checkbox(
            value: task.done,
            onChanged: (_) => _toggleTask(task),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration:
                  task.done ? TextDecoration.lineThrough : TextDecoration.none,
              color: task.done ? Colors.black38 : null,
            ),
          ),
          subtitle: Text(
            '${task.category} • ${DateFormat('HH:mm').format(task.date)}'
            '${late ? ' • معوق' : ''}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black38),
            onPressed: () => _deleteTask(task),
          ),
          onTap: () => _showTaskDetails(task),
        ),
      );

  Future<void> _showTaskDetails(Task task) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.note.isEmpty ? 'بدون یادداشت' : task.note),
              if (task.imagePath != null && File(task.imagePath!).existsSync())
                Image.file(File(task.imagePath!)),
              if (task.audioPath != null)
                Text('فایل صوتی: ${task.audioPath!.split('/').last}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final recorder = AudioRecorder();

  DateTime date = DateTime.now();
  DateTime? reminder;
  String category = categories.first;
  String? imagePath;
  String? audioPath;
  bool recording = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          date.hour,
          date.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (picked != null) {
      setState(() {
        date = DateTime(
          date.year,
          date.month,
          date.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => imagePath = picked.path);
  }

  Future<void> _toggleRecording() async {
    if (recording) {
      final path = await recorder.stop();
      setState(() {
        recording = false;
        audioPath = path;
      });
      return;
    }
    if (await recorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${const Uuid().v4()}.m4a';
      await recorder.start(const RecordConfig(), path: path);
      setState(() => recording = true);
    }
  }

  Future<void> _pickReminder() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: date.isBefore(DateTime.now()) ? DateTime.now() : date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (pickedTime != null) {
      setState(() {
        reminder = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('افزودن کار')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان کار',
                prefixIcon: Icon(Icons.edit_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: 14),
            _action(
              Icons.calendar_month,
              'تاریخ: ${DateFormat('yyyy/MM/dd').format(date)}',
              _pickDate,
            ),
            _action(
              Icons.access_time,
              'ساعت: ${DateFormat('HH:mm').format(date)}',
              _pickTime,
            ),
            _action(
              Icons.notifications_active_outlined,
              reminder == null
                  ? 'تنظیم یادآور'
                  : 'یادآور: ${DateFormat('yyyy/MM/dd HH:mm').format(reminder!)}',
              _pickReminder,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'یادداشت',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(imagePath == null ? 'افزودن تصویر' : 'تصویر انتخاب شد'),
            ),
            OutlinedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(recording ? Icons.stop : Icons.mic_none),
              label: Text(recording ? 'توقف ضبط' : 'ضبط یادداشت صوتی'),
            ),
            if (audioPath != null) const Text('یادداشت صوتی ذخیره شد'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saveTask,
              icon: const Icon(Icons.check),
              label: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('ذخیره کار'),
              ),
            ),
          ],
        ),
      );

  void _saveTask() {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان کار را وارد کنید')),
      );
      return;
    }
    Navigator.pop(
      context,
      Task(
        id: const Uuid().v4(),
        title: titleController.text.trim(),
        date: date,
        category: category,
        note: noteController.text.trim(),
        imagePath: imagePath,
        audioPath: audioPath,
        reminder: reminder,
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onPressed) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Align(
            alignment: Alignment.centerRight,
            child: Text(label),
          ),
        ),
      );
}
