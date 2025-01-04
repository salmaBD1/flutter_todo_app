import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ToDo {
  final String id;
  String title;
  bool isCompleted;
  DateTime? reminderTime;
  String category;

  ToDo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.reminderTime,
    required this.category,
  });
// transform the class into map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'reminderTime': reminderTime?.toIso8601String(),
      'category': category,
    };
  }

  //converts Firestore data into a ToDo object
  factory ToDo.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ToDo(
      id: data['id'],
      title: data['title'],
      isCompleted: data['isCompleted'],
      reminderTime: data['reminderTime'] != null
          ? DateTime.parse(data['reminderTime'])
          : null,
      category: data['category'] ?? 'Work',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cutesy To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Poppins', fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
      ),
      home: const ToDoListScreen(),
    );
  }
}

class ToDoListScreen extends StatefulWidget {
  const ToDoListScreen({super.key});

  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  final List<ToDo> toDoList = [];
  final TextEditingController searchController = TextEditingController();
  final TextEditingController addController = TextEditingController();
  final TextEditingController editController = TextEditingController();
  List<ToDo> filteredList = [];
  DateTime? reminderTime;
  String selectedCategory = 'Work';

  @override
  void initState() {
    super.initState();
    fetchToDos();
  }

  Future<void> fetchToDos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('todos').get();
      final todos = snapshot.docs.map((doc) => ToDo.fromDocument(doc)).toList();
      setState(() {
        toDoList.addAll(todos);
        filteredList = List.from(toDoList);
      });
    } catch (e) {
      print('Error fetching ToDos: $e');
    }
  }

  void addToDo(String title, DateTime? reminderTime, String category) async {
    final newToDo = ToDo(
      id: Random().nextInt(1000).toString(),
      title: title,
      reminderTime: reminderTime,
      category: category,
    );

    try {
      await FirebaseFirestore.instance.collection('todos').add(newToDo.toMap());
      setState(() {
        toDoList.add(newToDo);
        filteredList = List.from(toDoList);
      });
    } catch (e) {
      print('Error adding ToDo: $e');
    }
  }

  void editToDoInFirestore(ToDo todo) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('todos')
          .where('id', isEqualTo: todo.id)
          .get();
      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await FirebaseFirestore.instance
            .collection('todos')
            .doc(docId)
            .update({'title': todo.title, 'category': todo.category});
        setState(() {
          filteredList = List.from(toDoList);
        });
      }
    } catch (e) {
      print('Error editing ToDo: $e');
    }
  }

  void deleteToDoInFirestore(String id) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('todos')
          .where('id', isEqualTo: id)
          .get();
      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await FirebaseFirestore.instance
            .collection('todos')
            .doc(docId)
            .delete();
        setState(() {
          toDoList.removeWhere((todo) => todo.id == id);
          filteredList = List.from(toDoList);
        });
      }
    } catch (e) {
      print('Error deleting ToDo: $e');
    }
  }

  void toggleTaskCompletion(String id) {
    setState(() {
      final task = toDoList.firstWhere((todo) => todo.id == id);
      task.isCompleted = !task.isCompleted;
      filteredList = List.from(toDoList);
    });
  }

  void searchToDo(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = List.from(toDoList);
      } else {
        filteredList = toDoList
            .where((todo) =>
                todo.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> selectReminderTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: reminderTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != reminderTime) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(reminderTime ?? DateTime.now()),
      );
      if (time != null) {
        final selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        setState(() {
          reminderTime = selectedDate;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plan Your Tasks',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 223, 43, 133),
                Color.fromARGB(255, 0, 0, 0)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: searchToDo,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.pink[50],
                prefixIcon: const Icon(Icons.search, color: Colors.pink),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.pink, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final todo = filteredList[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${todo.category}'),
                        if (todo.reminderTime != null)
                          Text(
                            'Reminder: ${todo.reminderTime!.toLocal().toString()}',
                          ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 12,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.pink),
                          onPressed: () {
                            editController.text = todo.title;
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: Colors.pink[50],
                                  title: const Text(
                                    'Edit Task',
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: editController,
                                        decoration: InputDecoration(
                                          hintText: 'Edit task title...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: todo.category,
                                        onChanged: (newCategory) {
                                          setState(() {
                                            todo.category = newCategory!;
                                          });
                                        },
                                        items: [
                                          'Work',
                                          'Personal',
                                          'Health',
                                          'Study'
                                        ].map<DropdownMenuItem<String>>(
                                          (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          },
                                        ).toList(),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          await selectReminderTime(
                                              context); // Use the same reminder time selection
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.pink),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            todo.reminderTime == null
                                                ? 'Select Reminder Time'
                                                : 'Reminder: ${todo.reminderTime!.toLocal().toString()}',
                                            style: const TextStyle(
                                                color: Colors.pink),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        todo.title = editController.text;
                                        todo.reminderTime =
                                            reminderTime; // Update reminder time
                                        editToDoInFirestore(todo);
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.pink,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            deleteToDoInFirestore(todo.id);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            todo.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: Colors.pink,
                          ),
                          onPressed: () {
                            toggleTaskCompletion(todo.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                final result = await showDialog<DateTime>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Add New Task'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: addController,
                            decoration: const InputDecoration(
                              labelText: 'Task Title',
                            ),
                          ),
                          DropdownButton<String>(
                            value: selectedCategory,
                            onChanged: (newCategory) {
                              setState(() {
                                selectedCategory = newCategory!;
                              });
                            },
                            items: ['Work', 'Personal', 'Health', 'Study']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await selectReminderTime(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.pink),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                reminderTime == null
                                    ? 'Select Reminder Time'
                                    : 'Reminder: ${reminderTime!.toLocal().toString()}',
                                style: const TextStyle(color: Colors.pink),
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.pink),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            addToDo(
                              addController.text,
                              reminderTime,
                              selectedCategory,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Add',
                            style: TextStyle(color: Colors.pink),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
