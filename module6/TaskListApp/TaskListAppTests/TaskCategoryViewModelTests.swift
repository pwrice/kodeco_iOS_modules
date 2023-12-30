//
//  TaskListViewModelTests.swift
//  TaskListAppTests
//
//  Created by Peter Rice on 12/29/23.
//

import XCTest

final class TaskCategoryViewModelTests: XCTestCase {
  var tasksStore: TasksStore?
  var taskListViewModel: InlineTaskCategoryViewModel?
  
  let testTasks = [
    Task(title: "Task 1", isCompleted: false, notes: "", category: .home),
    Task(title: "Task 2", isCompleted: false, notes: "", category: .work),
    Task(title: "Task 3", isCompleted: true, notes: "", category: .personal),
    Task(title: "Task 4", isCompleted: true, notes: "", category: .none),
  ]

  override func setUpWithError() throws {
    tasksStore = TasksStore(with: testTasks)
    taskListViewModel = InlineTaskCategoryViewModel(tasksStore: tasksStore!)
  }
  
  override func tearDownWithError() throws {
  }
  
  func testTaskListViewModelInit() throws {
    XCTAssertEqual(taskListViewModel!.selectedCategory, nil)
    XCTAssertEqual(taskListViewModel!.categories, tasksStore!.categories)
  }
  
  func testTasksByCategory() throws {
    XCTAssertEqual(taskListViewModel!.selectedCategory, nil)
    var categoryTasks = taskListViewModel!.tasksForSelectedCategory
    XCTAssertEqual(categoryTasks.count, 4)
        
    for category in taskListViewModel!.categories {
      taskListViewModel!.selectedCategory = category
      categoryTasks = taskListViewModel!.tasksForSelectedCategory
      XCTAssertEqual(categoryTasks.count, 1)
      XCTAssertEqual(categoryTasks.first?.category, category)
    }
  }
  
  func testTaskCategoryCounts() throws {
    for category in taskListViewModel!.categories {
      taskListViewModel!.selectedCategory = category
      XCTAssertEqual(taskListViewModel!.taskCount(for: category), 1)
    }
  }
  
  func testTapCategoryUpdatesList() throws {
    XCTAssertEqual(taskListViewModel!.selectedCategory, nil)
    XCTAssertEqual(taskListViewModel!.tasksForSelectedCategory.count, 4)
        
    for category in taskListViewModel!.categories {
      taskListViewModel!.tapCategory(category: category)
      XCTAssertEqual(taskListViewModel!.selectedCategory, category)
      let tasksForCategory = taskListViewModel!.tasksForSelectedCategory
      XCTAssertEqual(tasksForCategory.count, 1)
      XCTAssertEqual(tasksForCategory.first?.category, category)
    }
  }
  
  func testTapCategoryTwiceResetsList() throws {
    // First tap
    taskListViewModel!.tapCategory(category: .home)
    XCTAssertEqual(taskListViewModel!.selectedCategory, .home)
    var tasksForCategory = taskListViewModel!.tasksForSelectedCategory
    XCTAssertEqual(tasksForCategory.count, 1)
    XCTAssertEqual(tasksForCategory.first?.category, .home)
    
    // Second tap
    taskListViewModel!.tapCategory(category: .home)
    XCTAssertEqual(taskListViewModel!.selectedCategory, nil)
    tasksForCategory = taskListViewModel!.tasksForSelectedCategory
    XCTAssertEqual(tasksForCategory.count, 4)
  }
}
