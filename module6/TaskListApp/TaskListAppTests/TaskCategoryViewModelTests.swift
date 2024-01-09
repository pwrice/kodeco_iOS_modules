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
    XCTAssertEqual(taskListViewModel!.selectedCategory, nil, "taskListViewModel.selectedCategory is initially nil but found \(String(describing: taskListViewModel!.selectedCategory))")
    XCTAssertEqual(taskListViewModel!.categories, tasksStore!.categories, "taskListViewModel.categories initially should == tasksStore.categories but found \(taskListViewModel!.categories)")
  }
  
  func testTasksByCategory() throws {
    for category in taskListViewModel!.categories {
      taskListViewModel!.selectedCategory = category
      let categoryTasks = taskListViewModel!.tasksForSelectedCategory
      XCTAssertEqual(categoryTasks.count, 1, "There should be 1 task for each category; found \(categoryTasks.count) ")
      XCTAssertEqual(categoryTasks.first?.category, category, "The category shold match the selected category \(category); found \(String(describing: categoryTasks.first?.category))")
    }
  }
  
  func testTaskCategoryCounts() throws {
    for category in taskListViewModel!.categories {
      taskListViewModel!.selectedCategory = category
      let taskCount = taskListViewModel!.taskCount(for: category)
      XCTAssertEqual(taskCount, 1, "There should be 1 task for each category, found \(taskCount) for \(category)")
    }
  }
  
  func testTapCategoryUpdatesList() throws {
    for category in taskListViewModel!.categories {
      taskListViewModel!.tapCategory(category: category)
      XCTAssertEqual(taskListViewModel!.selectedCategory, category, "The selected category \(String(describing: taskListViewModel!.selectedCategory)) should match the tapped category \(category)")
      let tasksForCategory = taskListViewModel!.tasksForSelectedCategory
      XCTAssertEqual(tasksForCategory.count, 1, "There should be 1 task for category \(category); found \(tasksForCategory.count) ")
      XCTAssertEqual(tasksForCategory.first?.category, category, "The category should match the selected category \(category); found \(String(describing: tasksForCategory.first?.category))")
    }
  }
  
  func testTapCategoryTwiceResetsList() throws {
    // First tap
    taskListViewModel!.tapCategory(category: .home)
    XCTAssertEqual(taskListViewModel!.selectedCategory, .home, "First tap should set selectec category to home, found \(String(describing: taskListViewModel!.selectedCategory))")
    var tasksForCategory = taskListViewModel!.tasksForSelectedCategory
    XCTAssertEqual(tasksForCategory.count, 1, "There should be 1 task for the .home category; found \(tasksForCategory.count) ")
    XCTAssertEqual(tasksForCategory.first?.category, .home, "The task.category should be .home; found \(String(describing: tasksForCategory.first?.category))")

    // Second tap
    taskListViewModel!.tapCategory(category: .home)
    XCTAssertEqual(taskListViewModel!.selectedCategory, nil, "Second tap should set selectec category back to nil, found \(String(describing: taskListViewModel!.selectedCategory))")
    tasksForCategory = taskListViewModel!.tasksForSelectedCategory
    XCTAssertEqual(tasksForCategory.count, 4, "All 4 tasks should be visible; found \(tasksForCategory.count)")
  }
}
