//
//  TasksStore.swift
//  TaskListApp
//
//  Created by Peter Rice on 12/22/23.
//

import Foundation

class TasksStore: ObservableObject {
  let defaultTasks = [
    Task(id: UUID(), title: "Task 1", isCompleted: false, notes: ""),
    Task(id: UUID(), title: "Task 2", isCompleted: false, notes: ""),
    Task(id: UUID(), title: "Task 3", isCompleted: false, notes: ""),
    Task(id: UUID(), title: "Task 4", isCompleted: false, notes: ""),
    Task(id: UUID(), title: "Task 5", isCompleted: true, notes: "some notes"),
    Task(id: UUID(), title: "Task 6", isCompleted: false, notes: ""),
    Task(id: UUID(), title: "Task 7", isCompleted: false, notes: ""),
    Task(id: UUID(), title: "Task 8", isCompleted: false, notes: ""),
    Task(id: UUID(), title: "Task 9", isCompleted: false, notes: ""),
    Task(id: UUID(), title: "Task 10", isCompleted: false, notes: "")
  ]
  
  @Published var tasks: [Task]
  
  init() {
    tasks = defaultTasks
  }
  
  func addTask(title: String, notes: String) {
    tasks.append(Task(id: UUID(), title: title, isCompleted: false, notes: notes))
  }
    
  func setTask(with id: UUID, completed: Bool) {
    if var taskToUpdate = tasks.first(where: { $0.id == id}) {
      taskToUpdate.isCompleted = completed
      tasks = tasks.map({
        $0.id == id ? taskToUpdate : $0
      })
    }
  }
}

struct Task: Identifiable, Hashable {
  let id: UUID
  var title: String
  var isCompleted: Bool
  var notes: String
}
