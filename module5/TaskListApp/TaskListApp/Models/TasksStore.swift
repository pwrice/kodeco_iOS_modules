//
//  TasksStore.swift
//  TaskListApp
//
//  Created by Peter Rice on 12/22/23.
//

import Foundation

class TasksStore: ObservableObject {
  let defaultTasks = [
    Task(title: "Task 1", isCompleted: false, notes: ""),
    Task(title: "Task 2", isCompleted: false, notes: ""),
    Task(title: "Task 3", isCompleted: false, notes: ""),
    Task(title: "Task 4", isCompleted: false, notes: ""),
    Task(title: "Task 5", isCompleted: true, notes: "some notes"),
    Task(title: "Task 6", isCompleted: false, notes: ""),
    Task(title: "Task 7", isCompleted: false, notes: ""),
    Task(title: "Task 8", isCompleted: false, notes: ""),
    Task(title: "Task 9", isCompleted: false, notes: ""),
    Task(title: "Task 10", isCompleted: false, notes: "")
  ]
  
  @Published var tasks: [Task]
  
  init() {
    tasks = defaultTasks
  }
  
  func addTask(title: String, notes: String) {
    tasks.append(Task(title: title, notes: notes))
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
  let id = UUID()
  var title: String
  var isCompleted: Bool
  var notes: String
  
  init(title: String, isCompleted: Bool = false, notes: String) {
    self.title = title
    self.isCompleted = isCompleted
    self.notes = notes
  }
}
