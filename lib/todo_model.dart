class ToDo {
  String id;
  String title;
  bool isCompleted;

  ToDo({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}
