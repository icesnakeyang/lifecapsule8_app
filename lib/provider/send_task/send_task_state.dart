import 'send_task_model.dart';

class SendTaskState {
  final List<SendTask> tasks;

  const SendTaskState({required this.tasks});

  SendTaskState copyWith({List<SendTask>? tasks}) {
    return SendTaskState(tasks: tasks ?? this.tasks);
  }

  static const empty = SendTaskState(tasks: []);
}
