//
//  TasksStoreTests.swift
//  TasksStoreTests
//
//  Created by Peter Rice on 12/29/23.
//

import XCTest

final class TasksStoreTests: XCTestCase {
  var tasksStore: TasksStore?

  let testTasks = [
    Task(title: "Task 1", isCompleted: false, notes: "", category: .home),
    Task(title: "Task 2", isCompleted: false, notes: "", category: .work),
    Task(title: "Task 3", isCompleted: true, notes: "", category: .personal),
    Task(title: "Task 4", isCompleted: true, notes: "", category: .none),
  ]
  
  override func setUpWithError() throws {
    tasksStore = TasksStore()
  }
  
  override func tearDownWithError() throws {}
  
  func testDefaultTasks() throws {
    XCTAssertEqual(tasksStore!.tasks, tasksStore!.defaultTasks)
    XCTAssertEqual(tasksStore!.tasks.count, 10)
  }

  func testSetTaskComplete() throws {
    let firstTask = tasksStore!.tasks.first!
    let firstTaskId = firstTask.id
    XCTAssertEqual(firstTask.isCompleted, false)

    tasksStore?.setTask(with: firstTaskId, completed: true)
    
    let taskIndex = tasksStore!.tasks.firstIndex(where: { $0.id == firstTaskId })!
    let updatedTask = tasksStore!.tasks[taskIndex]
    XCTAssertEqual(updatedTask.isCompleted, true)
    XCTAssertEqual(taskIndex, 0)
  }

  func testAddTask() throws {
    let originalTaskList = tasksStore!.tasks
    XCTAssertEqual(originalTaskList.count, 10)
    
    let newTaskTitle = "New Task Title"
    let newTaskNotes = "New Task Notes"
    XCTAssertNil(originalTaskList.first(where: { $0.title == newTaskTitle }))
    
    tasksStore?.addTask(title: newTaskTitle, notes: newTaskNotes)
    
    let updatedTaskList = tasksStore!.tasks
    XCTAssertEqual(updatedTaskList.count, 11)
    let newTask = updatedTaskList.first(where: { $0.title == newTaskTitle })!
    XCTAssertEqual(newTask.title, newTaskTitle)
    XCTAssertEqual(newTask.notes, newTaskNotes)
    XCTAssertNil(originalTaskList.first(where: { $0.id == newTask.id }))
  }
  
  func testCompletedTasks() throws {
    XCTAssertEqual(tasksStore!.tasks, tasksStore!.defaultTasks)
    XCTAssertEqual(tasksStore!.tasks.count, 10)
    
    XCTAssertEqual(tasksStore!.completedTasks.count, 1)
    XCTAssertEqual(tasksStore!.completedTasks.first?.isCompleted, true)
  }

  func testUncompletedTasks() throws {
    XCTAssertEqual(tasksStore!.tasks, tasksStore!.defaultTasks)
    XCTAssertEqual(tasksStore!.tasks.count, 10)
    
    XCTAssertEqual(tasksStore!.uncompletedTasks.count, 9)
    for task in tasksStore!.uncompletedTasks {
      XCTAssertEqual(task.isCompleted, false)
    }
  }

  func testSearchUncompletedTasks() throws {
    tasksStore = TasksStore(with: testTasks)
    
    var matchingTasks = tasksStore!.searchUncompletedTasks(searchTerm: "1")
    XCTAssertEqual(matchingTasks.count, 1)
    XCTAssertEqual(matchingTasks.first?.title, "Task 1")

    matchingTasks = tasksStore!.searchUncompletedTasks(searchTerm: "3")
    XCTAssertEqual(matchingTasks.count, 0)
  }

  func testSearchCompletedTasks() throws {
    tasksStore = TasksStore(with: testTasks)
    
    var matchingTasks = tasksStore!.searchCompletedTasks(searchTerm: "3")
    XCTAssertEqual(matchingTasks.count, 1)
    XCTAssertEqual(matchingTasks.first?.title, "Task 3")

    matchingTasks = tasksStore!.searchCompletedTasks(searchTerm: "1")
    XCTAssertEqual(matchingTasks.count, 0)
  }
  
  func testTaskCategories() throws {
    let categories = tasksStore!.categories
    XCTAssertEqual(categories.count, 4)
    
    XCTAssertEqual(categories[0].rawValue, "Personal")
    XCTAssertEqual(categories[1].rawValue, "Work")
    XCTAssertEqual(categories[2].rawValue, "Home")
    XCTAssertEqual(categories[3].rawValue, "No Category")
  }
  
  func testTasksByCategory() throws {
    tasksStore = TasksStore(with: testTasks)
    for category in tasksStore!.categories {
      let categoryTasks = tasksStore!.tasks(for: category)
      XCTAssert(categoryTasks.count > 0)
      XCTAssertEqual(categoryTasks.first?.category, category)
    }
  }
}
