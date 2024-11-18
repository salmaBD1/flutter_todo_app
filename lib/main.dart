import 'package:flutter/material.dart';
import 'dart:math';

class ToDo {
  final String id;
  String title;
  bool isCompleted;

  ToDo({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colorful To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: ToDoListScreen(),
    );
  }
}

class ToDoListScreen extends StatefulWidget {
  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  final List<ToDo> toDoList = [];
  final TextEditingController searchController = TextEditingController();
  final TextEditingController addController = TextEditingController();
  final TextEditingController editController = TextEditingController();
  List<ToDo> filteredList = [];

  @override
  void initState() {
    super.initState();
    filteredList = toDoList;
  }

  void addToDo(String title) {
    setState(() {
      toDoList.add(ToDo(
        id: Random().nextInt(1000).toString(),
        title: title,
      ));
      filteredList = List.from(toDoList);
    });
  }

  void deleteToDo(String id) {
    setState(() {
      toDoList.removeWhere((todo) => todo.id == id);
      filteredList = List.from(toDoList);
    });
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

  void editToDo(ToDo todo) {
    setState(() {
      todo.title = editController.text;
      filteredList = List.from(toDoList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.blue],
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
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: Icon(Icons.search, color: Colors.purple),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.purple, width: 2),
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
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 12,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            editController.text = todo.title;
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: Colors.purple[50],
                                  title: Text(
                                    'Edit Task',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: TextField(
                                    controller: editController,
                                    decoration: InputDecoration(
                                      hintText: 'Edit task title...',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                            color: Colors.redAccent),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (editController.text.isNotEmpty) {
                                          editToDo(todo);
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        Checkbox(
                          value: todo.isCompleted,
                          onChanged: (value) =>
                              toggleTaskCompletion(todo.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => deleteToDo(todo.id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.purple[50],
                title: Text(
                  'Add Task',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: TextField(
                  controller: addController,
                  decoration: InputDecoration(
                    hintText: 'Task title...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (addController.text.isNotEmpty) {
                        addToDo(addController.text);
                        addController.clear();
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.edit), // Changed from Icons.add to Icons.edit
      ),
    );
  }
}
