//
//  TaskListViewModel.swift
//  TaskListApp
//
//  Created by Peter Rice on 12/29/23.
//

import Foundation

class InlineTaskCategoryViewModel: ObservableObject {
  @Published var tasksStore: TasksStore
  @Published var selectedCategory: TaskCategory? = nil
  
  var tasksForSelectedCategory: [Task] {
    tasksStore.tasks(for: selectedCategory)
  }
  
  var categories: [TaskCategory] {
    tasksStore.categories
  }
  
  func taskCount(for category: TaskCategory?) -> Int {
    tasksStore.taskCount(for: category)
  }
  
  func tapCategory(category: TaskCategory) {
    if selectedCategory == category {
      selectedCategory = nil
    } else {
      selectedCategory = category
    }
  }
  
  init(tasksStore: TasksStore, selectedCategory: TaskCategory? = nil) {
    self.tasksStore = tasksStore
    self.selectedCategory = selectedCategory
  }
}
