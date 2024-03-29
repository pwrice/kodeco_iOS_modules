//
//  TasksStore.swift
//  TaskListApp
//
//  Created by Peter Rice on 12/22/23.
//

import Foundation

class TasksStore: ObservableObject {
  let defaultTasks = [
    Task(title: "Task 1", isCompleted: false, notes: "", category: .home),
    Task(title: "Task 2", isCompleted: false, notes: "", category: .personal),
    Task(title: "Task 3", isCompleted: false, notes: "", category: .work),
    Task(title: "Task 4", isCompleted: false, notes: "", category: .none),
    Task(title: "Task 5", isCompleted: true, notes: "some notes", category: .home),
    Task(title: "Task 6", isCompleted: false, notes: "", category: .personal),
    Task(title: "Task 7", isCompleted: false, notes: "", category: .work),
    Task(title: "Task 8", isCompleted: false, notes: "", category: .none),
    Task(title: "Task 9", isCompleted: false, notes: "", category: .home),
    Task(title: "Task 10", isCompleted: false, notes: "", category: .personal)
  ]
  
  @Published var tasks: [Task]
  
  var completedTasks: [Task] {
    tasks.filter({ $0.isCompleted })
  }

  var uncompletedTasks: [Task] {
    tasks.filter({ !$0.isCompleted })
  }
  
  var categories: [TaskCategory] {
    TaskCategory.allCases
  }
  
  func tasks(for category: TaskCategory?) -> [Task] {
    guard let category = category else {
      return tasks
    }
    return tasks.filter({ $0.category == category })
  }
  
  func taskCount(for category: TaskCategory?) -> Int {
    tasks(for: category).count
  }

  func searchTasks(searchTerm: String, tasksList: [Task]) -> [Task] {
    if !searchTerm.isEmpty {
      return tasksList.filter {
        $0.title.lowercased().contains(searchTerm.lowercased())
      }
    }
    return tasksList

  }
  
  func searchCompletedTasks(searchTerm: String) -> [Task] {
    searchTasks(searchTerm: searchTerm, tasksList: completedTasks)
  }

  func searchUncompletedTasks(searchTerm: String) -> [Task] {
    searchTasks(searchTerm: searchTerm, tasksList: uncompletedTasks)
  }
  
  init() {
    tasks = defaultTasks
  }
  
  init(with inputTasks: [Task]) {
    tasks = inputTasks
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

enum TaskCategory: String, CaseIterable {
  case personal = "Personal"
  case work = "Work"
  case home = "Home"
  case none = "No Category"
}

struct Task: Identifiable, Hashable {
  let id = UUID()
  var title: String
  var isCompleted: Bool
  var notes: String
  var category: TaskCategory
  
  init(title: String, isCompleted: Bool = false, notes: String, category: TaskCategory = .none) {
    self.title = title
    self.isCompleted = isCompleted
    self.notes = notes
    self.category = category
  }
}
